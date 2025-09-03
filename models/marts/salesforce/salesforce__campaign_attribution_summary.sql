{{ config(
    materialized='table',
    partition_by={
        "field": "campaign_created_date",
        "data_type": "date"
    },
    cluster_by=['campaign_id', 'campaign_type']
) }}

with campaigns_base as (
    select 
        id as campaign_id,
        name as campaign_name,
        type as campaign_type,
        status as campaign_status,
        created_at as campaign_created_at,
        date(created_at) as campaign_created_date,
        actual_cost as campaign_cost,
        budgeted_cost,
        expected_revenue,
        start_date,
        end_date
    from {{ ref('stg_salesforce__campaigns') }}
),

lead_journey_data as (
    select 
        lead_id,
        first_touch_campaign_id,
        last_touch_campaign_id,
        opportunity_amount,
        opportunity_is_won,
        opportunity_is_closed,
        converted_opportunity_id,  
        is_converted,
        attribution_credit,
        days_campaign_to_conversion,
        coalesce(opportunity_amount, 0) as opp_amount,
        coalesce(attribution_credit * opportunity_amount, 0) as attributed_pipeline_value,
        case 
            when opportunity_is_won = true 
            then coalesce(attribution_credit * opportunity_amount, 0)
            else 0 
        end as attributed_revenue_value
    from {{ ref('int_salesforce__lead_journey') }}
),

campaign_attribution as (
    select
        c.campaign_id,
        c.campaign_name,
        c.campaign_type,
        c.campaign_status,
        c.campaign_created_date,
        c.campaign_cost,
        c.budgeted_cost,
        c.expected_revenue,
        c.start_date,
        c.end_date,
        
        -- Lead counts
        count(distinct lj.lead_id) as total_leads,
        count(distinct case when lj.is_converted = true then lj.lead_id end) as converted_leads,
        count(distinct case when lj.converted_opportunity_id is not null then lj.lead_id end) as leads_with_opportunities,
        count(distinct case when lj.opportunity_is_won = true then lj.lead_id end) as leads_with_won_opportunities,
        
        -- Opportunity counts
        count(distinct lj.converted_opportunity_id) as total_opportunities,
        count(distinct case when lj.opportunity_is_won = true then lj.converted_opportunity_id end) as won_opportunities,
        count(distinct case when lj.opportunity_is_closed = true and lj.opportunity_is_won = false then lj.converted_opportunity_id end) as lost_opportunities,
        
        -- First-touch attribution
        sum(case 
            when lj.first_touch_campaign_id = c.campaign_id 
            then lj.opp_amount 
            else 0 
        end) as first_touch_pipeline,
        
        sum(case 
            when lj.first_touch_campaign_id = c.campaign_id and lj.opportunity_is_won = true
            then lj.opp_amount 
            else 0 
        end) as first_touch_revenue,
        
        -- Last-touch attribution
        sum(case 
            when lj.last_touch_campaign_id = c.campaign_id 
            then lj.opp_amount 
            else 0 
        end) as last_touch_pipeline,
        
        sum(case 
            when lj.last_touch_campaign_id = c.campaign_id and lj.opportunity_is_won = true
            then lj.opp_amount 
            else 0 
        end) as last_touch_revenue,
        
        -- Multi-touch attribution
        coalesce(sum(lj.attributed_pipeline_value), 0) as multi_touch_pipeline,
        coalesce(sum(lj.attributed_revenue_value), 0) as multi_touch_revenue,
        
        -- Response metrics (placeholder - will be enhanced later)
        0 as first_touch_responses,
        0 as last_touch_responses,
        
        -- Timing metrics
        avg(case when lj.first_touch_campaign_id = c.campaign_id then lj.days_campaign_to_conversion end) as avg_days_to_conversion_first_touch,
        avg(case when lj.last_touch_campaign_id = c.campaign_id then lj.days_campaign_to_conversion end) as avg_days_to_conversion_last_touch
        
    from campaigns_base c
    left join lead_journey_data lj 
        on c.campaign_id in (lj.first_touch_campaign_id, lj.last_touch_campaign_id)
    left join {{ ref('stg_salesforce__campaign_members') }} cm
        on c.campaign_id = cm.campaign_id 
           and cm.lead_id = lj.lead_id 
           and cm.member_type = 'Lead'
    group by 1,2,3,4,5,6,7,8,9,10
),

final as (
    select 
        *,
        
        -- Conversion rates
        case 
            when total_leads > 0 
            then round(converted_leads * 100.0 / total_leads, 2)
            else 0 
        end as lead_conversion_rate_pct,
        
        case 
            when converted_leads > 0 
            then round(leads_with_opportunities * 100.0 / converted_leads, 2)
            else 0 
        end as opportunity_creation_rate_pct,
        
        case 
            when total_opportunities > 0 
            then round(won_opportunities * 100.0 / total_opportunities, 2)
            else 0 
        end as opportunity_win_rate_pct,
        
        -- Attribution ROI (first-touch)
        case 
            when first_touch_pipeline > 0 and campaign_cost > 0
            then round(first_touch_pipeline / campaign_cost, 2)
            else 0 
        end as first_touch_pipeline_roi,
        
        case 
            when first_touch_revenue > 0 and campaign_cost > 0
            then round(first_touch_revenue / campaign_cost, 2)
            else 0 
        end as first_touch_revenue_roi,
        
        -- Attribution ROI (last-touch)
        case 
            when last_touch_pipeline > 0 and campaign_cost > 0
            then round(last_touch_pipeline / campaign_cost, 2)
            else 0 
        end as last_touch_pipeline_roi,
        
        case 
            when last_touch_revenue > 0 and campaign_cost > 0
            then round(last_touch_revenue / campaign_cost, 2)
            else 0 
        end as last_touch_revenue_roi,
        
        -- Attribution ROI (multi-touch)
        case 
            when multi_touch_pipeline > 0 and campaign_cost > 0
            then round(multi_touch_pipeline / campaign_cost, 2)
            else 0 
        end as multi_touch_pipeline_roi,
        
        case 
            when multi_touch_revenue > 0 and campaign_cost > 0
            then round(multi_touch_revenue / campaign_cost, 2)
            else 0 
        end as multi_touch_revenue_roi,
        
        -- Response rates
        case 
            when total_leads > 0
            then round((first_touch_responses + last_touch_responses) * 100.0 / total_leads, 2)
            else 0 
        end as response_rate_pct
        
    from campaign_attribution
)

select * from final