{{ config(materialized='view') }}

with campaigns_base as (
    select 
        id as campaign_id,
        name as campaign_name,
        type as campaign_type,
        status as campaign_status,
        actual_cost,
        budgeted_cost,
        expected_revenue,
        created_at as campaign_created_at,
        start_date as campaign_start_date,
        end_date as campaign_end_date
    from {{ ref('stg_salesforce__campaigns') }}
),

lead_metrics as (
    select 
        cm.campaign_id,
        count(*) as total_leads_created,
        sum(case when l.is_converted = true then 1 else 0 end) as total_leads_converted,
        avg(case when l.is_converted = true then l.days_to_conversion end) as avg_days_to_conversion
    from {{ ref('stg_salesforce__campaign_members') }} cm
    inner join {{ ref('stg_salesforce__leads') }} l 
        on cm.lead_id = l.id
    where cm.member_type = 'Lead'
    group by cm.campaign_id
),

campaign_member_metrics as (
    select 
        campaign_id,
        count(*) as total_members,
        sum(case when has_responded = true then 1 else 0 end) as responded_members,
        avg(case when has_responded = true then days_to_response end) as avg_days_to_response
    from {{ ref('stg_salesforce__campaign_members') }}
    group by campaign_id
),

opportunity_metrics as (
    select 
        o.campaign_id,
        count(*) as influenced_opportunities,
        sum(case when o.is_won = true then 1 else 0 end) as won_opportunities,
        sum(coalesce(o.amount, 0)) as total_opportunity_amount,
        sum(case when o.is_won = true then coalesce(o.amount, 0) else 0 end) as won_opportunity_amount,
        avg(case when o.is_closed = true then o.sales_cycle_days end) as avg_sales_cycle,
        avg(case when o.campaign_id is not null then 
            date_diff(date(o.created_at), date(c.campaign_created_at), day) 
        end) as avg_days_to_opportunity
    from {{ ref('stg_salesforce__opportunities') }} o
    left join campaigns_base c on o.campaign_id = c.campaign_id
    where o.campaign_id is not null
    group by o.campaign_id
),

final as (
    select 
        c.campaign_id,
        c.campaign_name,
        c.campaign_type,
        c.campaign_status,
        c.actual_cost,
        c.budgeted_cost,
        c.expected_revenue,
        c.campaign_created_at,
        c.campaign_start_date,
        c.campaign_end_date,
        
        -- Lead metrics
        coalesce(lm.total_leads_created, 0) as total_leads_created,
        coalesce(lm.total_leads_converted, 0) as total_leads_converted,
        safe_divide(lm.total_leads_converted, lm.total_leads_created) as lead_conversion_rate,
        lm.avg_days_to_conversion,
        
        -- Campaign member metrics  
        coalesce(cmm.total_members, 0) as total_members,
        coalesce(cmm.responded_members, 0) as responded_members,
        safe_divide(cmm.responded_members, cmm.total_members) as response_rate,
        cmm.avg_days_to_response,
        
        -- Opportunity metrics
        coalesce(om.influenced_opportunities, 0) as influenced_opportunities,
        coalesce(om.won_opportunities, 0) as won_opportunities,
        coalesce(om.total_opportunity_amount, 0) as total_opportunity_amount,
        coalesce(om.won_opportunity_amount, 0) as won_opportunity_amount,
        om.avg_sales_cycle,
        om.avg_days_to_opportunity,
        
        -- ROI calculations
        safe_divide(c.actual_cost, nullif(lm.total_leads_created, 0)) as cost_per_lead,
        safe_divide(c.actual_cost, nullif(lm.total_leads_converted, 0)) as cost_per_conversion,
        safe_divide(c.actual_cost, nullif(om.won_opportunities, 0)) as cost_per_acquisition,
        safe_divide(om.won_opportunity_amount, nullif(c.actual_cost, 0)) as roi_ratio,
        safe_divide(om.won_opportunity_amount - c.actual_cost, nullif(c.actual_cost, 0)) * 100 as roi_percentage
        
    from campaigns_base c
    left join lead_metrics lm on c.campaign_id = lm.campaign_id
    left join campaign_member_metrics cmm on c.campaign_id = cmm.campaign_id
    left join opportunity_metrics om on c.campaign_id = om.campaign_id
)

select * from final