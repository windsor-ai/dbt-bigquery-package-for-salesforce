-- Test to ensure campaign performance aggregations match staging model totals
-- This test validates that our intermediate model correctly aggregates data from staging

with campaign_performance_totals as (
    select 
        sum(total_leads_created) as agg_total_leads,
        sum(total_leads_converted) as agg_total_conversions,
        sum(total_members) as agg_total_members,
        sum(responded_members) as agg_total_responses,
        sum(influenced_opportunities) as agg_total_opportunities,
        sum(won_opportunities) as agg_total_won_opps,
        sum(total_opportunity_amount) as agg_total_opp_amount,
        sum(won_opportunity_amount) as agg_total_won_amount
    from {{ ref('int_salesforce__campaign_performance') }}
),

staging_totals as (
    select 
        -- Count leads by campaign
        (select count(distinct l.id) 
         from {{ ref('stg_salesforce__campaign_members') }} cm 
         inner join {{ ref('stg_salesforce__leads') }} l on cm.lead_id = l.id
         where cm.member_type = 'Lead') as staging_total_leads,
        
        -- Count converted leads by campaign 
        (select count(distinct l.id)
         from {{ ref('stg_salesforce__campaign_members') }} cm 
         inner join {{ ref('stg_salesforce__leads') }} l on cm.lead_id = l.id
         where cm.member_type = 'Lead' and l.is_converted = true) as staging_total_conversions,
        
        -- Count total campaign members
        (select count(*) from {{ ref('stg_salesforce__campaign_members') }}) as staging_total_members,
        
        -- Count responded campaign members
        (select count(*) from {{ ref('stg_salesforce__campaign_members') }} 
         where has_responded = true) as staging_total_responses,
        
        -- Count opportunities with campaign_id
        (select count(*) from {{ ref('stg_salesforce__opportunities') }}
         where campaign_id is not null) as staging_total_opportunities,
        
        -- Count won opportunities with campaign_id
        (select count(*) from {{ ref('stg_salesforce__opportunities') }}
         where campaign_id is not null and is_won = true) as staging_total_won_opps,
        
        -- Sum total opportunity amounts
        (select sum(coalesce(amount, 0)) from {{ ref('stg_salesforce__opportunities') }}
         where campaign_id is not null) as staging_total_opp_amount,
        
        -- Sum won opportunity amounts
        (select sum(case when is_won = true then coalesce(amount, 0) else 0 end) 
         from {{ ref('stg_salesforce__opportunities') }}
         where campaign_id is not null) as staging_total_won_amount
),

comparison as (
    select 
        -- Lead metrics comparison
        abs(cpt.agg_total_leads - st.staging_total_leads) as leads_diff,
        abs(cpt.agg_total_conversions - st.staging_total_conversions) as conversions_diff,
        
        -- Campaign member metrics comparison
        abs(cpt.agg_total_members - st.staging_total_members) as members_diff,
        abs(cpt.agg_total_responses - st.staging_total_responses) as responses_diff,
        
        -- Opportunity metrics comparison
        abs(cpt.agg_total_opportunities - st.staging_total_opportunities) as opportunities_diff,
        abs(cpt.agg_total_won_opps - st.staging_total_won_opps) as won_opps_diff,
        abs(cpt.agg_total_opp_amount - st.staging_total_opp_amount) as opp_amount_diff,
        abs(cpt.agg_total_won_amount - st.staging_total_won_amount) as won_amount_diff
        
    from campaign_performance_totals cpt
    cross join staging_totals st
)

-- Return rows where differences exceed tolerance (should be 0 for exact match)
select *
from comparison
where leads_diff > 0 
   or conversions_diff > 0
   or members_diff > 0 
   or responses_diff > 0
   or opportunities_diff > 0
   or won_opps_diff > 0
   or opp_amount_diff > 0.01  -- Allow small rounding differences for amounts
   or won_amount_diff > 0.01