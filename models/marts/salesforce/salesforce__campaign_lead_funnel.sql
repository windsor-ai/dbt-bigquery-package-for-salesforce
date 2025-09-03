{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='campaign_id',
    partition_by={'field': 'campaign_created_date', 'data_type': 'date'},
    cluster_by=['campaign_type', 'campaign_status', 'response_performance_tier'],
    labels={'data_domain': 'marketing', 'refresh_frequency': 'daily'}
) }}

with campaign_performance as (
    select * from {{ ref('int_salesforce__campaign_performance') }}
    {% if is_incremental() %}
        -- Only process campaigns that have been updated in the last 7 days
        where date(campaign_created_at) >= date_sub(current_date(), interval 7 day)
           or date(campaign_created_at) in (
               select distinct date(campaign_created_date)
               from {{ this }}
               where last_updated_at >= datetime_sub(current_datetime(), interval 2 day)
           )
    {% endif %}
),

lead_journey_aggregated as (
    select 
        first_touch_campaign_id as campaign_id,
        
        -- Funnel volume metrics by stage
        count(*) as total_leads_touched,
        sum(case when stage_1_lead_created is not null then 1 else 0 end) as stage_1_leads_created,
        sum(case when stage_2_campaign_member_added is not null then 1 else 0 end) as stage_2_campaign_members,
        sum(case when stage_3_lead_responded is not null then 1 else 0 end) as stage_3_leads_responded,
        sum(case when stage_4_lead_converted is not null then 1 else 0 end) as stage_4_leads_converted,
        sum(case when stage_5_opportunity_created is not null then 1 else 0 end) as stage_5_opportunities_created,
        sum(case when stage_6_opportunity_outcome = 'Opportunity Won' then 1 else 0 end) as stage_6_opportunities_won,
        
        -- Velocity metrics
        avg(case when days_lead_to_campaign is not null then days_lead_to_campaign end) as avg_days_lead_to_campaign,
        avg(case when days_campaign_to_conversion is not null then days_campaign_to_conversion end) as avg_days_campaign_to_conversion,
        avg(case when days_conversion_to_opportunity is not null then days_conversion_to_opportunity end) as avg_days_conversion_to_opportunity,
        avg(case when total_journey_days is not null then total_journey_days end) as avg_total_journey_days,
        avg(case when opportunity_sales_cycle_days is not null then opportunity_sales_cycle_days end) as avg_opportunity_sales_cycle,
        
        -- Financial metrics from lead journey
        sum(case when opportunity_amount is not null then opportunity_amount else 0 end) as total_pipeline_generated,
        sum(case when stage_6_opportunity_outcome = 'Opportunity Won' and opportunity_amount is not null then opportunity_amount else 0 end) as total_revenue_generated,
        
        -- Attribution-weighted metrics
        sum(case when attribution_credit is not null and opportunity_amount is not null 
                 then attribution_credit * opportunity_amount else 0 end) as attributed_pipeline_value,
        sum(case when attribution_credit is not null and stage_6_opportunity_outcome = 'Opportunity Won' and opportunity_amount is not null
                 then attribution_credit * opportunity_amount else 0 end) as attributed_revenue_value
        
    from {{ ref('int_salesforce__lead_journey') }}
    where first_touch_campaign_id is not null
    {% if is_incremental() %}
        -- Only process leads with recent campaign touches or recent opportunities
        and (date(first_campaign_touch_at) >= date_sub(current_date(), interval 7 day)
             or date(opportunity_created_at) >= date_sub(current_date(), interval 7 day)
             or date(opportunity_close_date) >= date_sub(current_date(), interval 7 day))
    {% endif %}
    group by first_touch_campaign_id
),

final as (
    select 
        cp.campaign_id,
        cp.campaign_name,
        cp.campaign_type,
        cp.campaign_status,
        cp.actual_cost,
        cp.budgeted_cost,
        cp.expected_revenue,
        date(cp.campaign_created_at) as campaign_created_date,
        cp.campaign_start_date,
        cp.campaign_end_date,
        
        -- Funnel Volume Metrics (combining both models for completeness)
        greatest(cp.total_members, coalesce(lja.total_leads_touched, 0)) as funnel_stage_1_total_touched,
        cp.total_leads_created as funnel_stage_2_leads_created,
        cp.responded_members as funnel_stage_3_members_responded,
        cp.total_leads_converted as funnel_stage_4_leads_converted,
        cp.influenced_opportunities as funnel_stage_5_opportunities_created,
        cp.won_opportunities as funnel_stage_6_opportunities_won,
        
        -- Stage-to-Stage Conversion Rates
        safe_divide(cp.total_leads_created, greatest(cp.total_members, coalesce(lja.total_leads_touched, 0))) as conversion_rate_touch_to_lead,
        cp.response_rate as conversion_rate_member_to_response,
        cp.lead_conversion_rate as conversion_rate_lead_to_conversion,
        safe_divide(cp.influenced_opportunities, nullif(cp.total_leads_converted, 0)) as conversion_rate_conversion_to_opportunity,
        safe_divide(cp.won_opportunities, nullif(cp.influenced_opportunities, 0)) as conversion_rate_opportunity_to_won,
        
        -- Overall funnel efficiency
        safe_divide(cp.won_opportunities, greatest(cp.total_members, coalesce(lja.total_leads_touched, 0))) as overall_funnel_conversion_rate,
        
        -- Financial Metrics
        cp.total_opportunity_amount as total_pipeline_generated,
        cp.won_opportunity_amount as total_revenue_generated,
        coalesce(lja.attributed_pipeline_value, cp.total_opportunity_amount) as attributed_pipeline_value,
        coalesce(lja.attributed_revenue_value, cp.won_opportunity_amount) as attributed_revenue_value,
        
        -- ROI Metrics
        cp.roi_ratio,
        cp.roi_percentage,
        safe_divide(cp.won_opportunity_amount - cp.actual_cost, nullif(cp.actual_cost, 0)) as net_roi_ratio,
        cp.won_opportunity_amount - coalesce(cp.actual_cost, 0) as net_revenue,
        
        -- Cost Efficiency Metrics  
        cp.cost_per_lead,
        cp.cost_per_conversion,
        cp.cost_per_acquisition,
        safe_divide(cp.actual_cost, nullif(cp.responded_members, 0)) as cost_per_response,
        safe_divide(cp.actual_cost, nullif(cp.influenced_opportunities, 0)) as cost_per_opportunity,
        
        -- Velocity Metrics
        cp.avg_days_to_conversion,
        cp.avg_sales_cycle,
        cp.avg_days_to_opportunity,
        coalesce(lja.avg_days_lead_to_campaign, 0) as avg_days_lead_to_campaign,
        coalesce(lja.avg_days_campaign_to_conversion, cp.avg_days_to_conversion) as avg_days_campaign_to_conversion,
        coalesce(lja.avg_days_conversion_to_opportunity, 0) as avg_days_conversion_to_opportunity,
        coalesce(lja.avg_total_journey_days, 0) as avg_total_journey_days,
        
        -- Campaign Performance Scores
        case 
            when cp.response_rate >= 0.15 then 'Excellent'
            when cp.response_rate >= 0.10 then 'Good'  
            when cp.response_rate >= 0.05 then 'Average'
            when cp.response_rate > 0 then 'Poor'
            else 'No Response'
        end as response_performance_tier,
        
        case 
            when cp.lead_conversion_rate >= 0.20 then 'Excellent'
            when cp.lead_conversion_rate >= 0.10 then 'Good'
            when cp.lead_conversion_rate >= 0.05 then 'Average'
            when cp.lead_conversion_rate > 0 then 'Poor'
            else 'No Conversions'
        end as conversion_performance_tier,
        
        case 
            when cp.roi_percentage >= 300 then 'Excellent'
            when cp.roi_percentage >= 100 then 'Good'
            when cp.roi_percentage >= 0 then 'Break Even'
            when cp.roi_percentage > -50 then 'Poor'
            else 'Loss'
        end as roi_performance_tier,
        
        -- Data quality flags
        case when cp.actual_cost is null or cp.actual_cost = 0 then true else false end as missing_cost_data,
        case when cp.total_members = 0 then true else false end as no_campaign_members,
        case when cp.campaign_start_date > current_date() then true else false end as future_campaign,
        
        -- Reporting metadata
        current_datetime() as last_updated_at
        
    from campaign_performance cp
    left join lead_journey_aggregated lja 
        on cp.campaign_id = lja.campaign_id
)

select * from final