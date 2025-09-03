-- Test funnel stage progression and data quality for campaign lead funnel mart
-- This test validates that the funnel stages follow logical progression and business rules

with funnel_data as (
    select 
        campaign_id,
        campaign_name,
        funnel_stage_1_total_touched,
        funnel_stage_2_leads_created,
        funnel_stage_3_members_responded,
        funnel_stage_4_leads_converted,
        funnel_stage_5_opportunities_created,
        funnel_stage_6_opportunities_won,
        
        -- Conversion rates
        conversion_rate_touch_to_lead,
        conversion_rate_member_to_response,
        conversion_rate_lead_to_conversion,
        conversion_rate_conversion_to_opportunity,
        conversion_rate_opportunity_to_won,
        overall_funnel_conversion_rate,
        
        -- Financial metrics
        total_pipeline_generated,
        total_revenue_generated,
        attributed_pipeline_value,
        attributed_revenue_value,
        actual_cost,
        roi_ratio,
        roi_percentage,
        net_revenue
        
    from {{ ref('salesforce__campaign_lead_funnel') }}
),

validation_failures as (
    select 
        campaign_id,
        campaign_name,
        'funnel_stage_progression' as test_category,
        case 
            -- Test 1: Each funnel stage should be <= previous stage
            when funnel_stage_2_leads_created > funnel_stage_1_total_touched then 
                'Stage 2 (leads: ' || funnel_stage_2_leads_created || ') > Stage 1 (touched: ' || funnel_stage_1_total_touched || ')'
            when funnel_stage_3_members_responded > funnel_stage_1_total_touched then
                'Stage 3 (responded: ' || funnel_stage_3_members_responded || ') > Stage 1 (touched: ' || funnel_stage_1_total_touched || ')'
            when funnel_stage_4_leads_converted > funnel_stage_2_leads_created then
                'Stage 4 (converted: ' || funnel_stage_4_leads_converted || ') > Stage 2 (leads: ' || funnel_stage_2_leads_created || ')'
            when funnel_stage_5_opportunities_created > funnel_stage_4_leads_converted and funnel_stage_4_leads_converted > 0 then
                'Stage 5 (opportunities: ' || funnel_stage_5_opportunities_created || ') > Stage 4 (converted: ' || funnel_stage_4_leads_converted || ')'
            when funnel_stage_6_opportunities_won > funnel_stage_5_opportunities_created then
                'Stage 6 (won: ' || funnel_stage_6_opportunities_won || ') > Stage 5 (opportunities: ' || funnel_stage_5_opportunities_created || ')'
            else null
        end as stage_progression_failure,
        
        case 
            -- Test 2: No negative conversion rates
            when conversion_rate_touch_to_lead < 0 then 'Negative touch to lead conversion rate: ' || conversion_rate_touch_to_lead
            when conversion_rate_member_to_response < 0 then 'Negative member to response conversion rate: ' || conversion_rate_member_to_response  
            when conversion_rate_lead_to_conversion < 0 then 'Negative lead to conversion rate: ' || conversion_rate_lead_to_conversion
            when conversion_rate_conversion_to_opportunity < 0 then 'Negative conversion to opportunity rate: ' || conversion_rate_conversion_to_opportunity
            when conversion_rate_opportunity_to_won < 0 then 'Negative opportunity to won rate: ' || conversion_rate_opportunity_to_won
            when overall_funnel_conversion_rate < 0 then 'Negative overall funnel conversion rate: ' || overall_funnel_conversion_rate
            else null
        end as negative_conversion_rate_failure,
        
        case 
            -- Test 3: Conversion rates should not exceed 100%
            when conversion_rate_touch_to_lead > 1 then 'Touch to lead conversion rate > 100%: ' || conversion_rate_touch_to_lead
            when conversion_rate_member_to_response > 1 then 'Member to response conversion rate > 100%: ' || conversion_rate_member_to_response
            when conversion_rate_lead_to_conversion > 1 then 'Lead to conversion rate > 100%: ' || conversion_rate_lead_to_conversion
            when conversion_rate_opportunity_to_won > 1 then 'Opportunity to won rate > 100%: ' || conversion_rate_opportunity_to_won
            when overall_funnel_conversion_rate > 1 then 'Overall funnel conversion rate > 100%: ' || overall_funnel_conversion_rate
            else null
        end as excessive_conversion_rate_failure,
        
        case 
            -- Test 4: Revenue amounts should be non-negative
            when total_pipeline_generated < 0 then 'Negative total pipeline generated: ' || total_pipeline_generated
            when total_revenue_generated < 0 then 'Negative total revenue generated: ' || total_revenue_generated
            when attributed_pipeline_value < 0 then 'Negative attributed pipeline value: ' || attributed_pipeline_value
            when attributed_revenue_value < 0 then 'Negative attributed revenue value: ' || attributed_revenue_value
            else null
        end as negative_revenue_failure,
        
        case 
            -- Test 5: Revenue consistency checks
            when attributed_revenue_value > total_revenue_generated and attributed_revenue_value is not null and total_revenue_generated is not null then 
                'Attributed revenue (' || attributed_revenue_value || ') > total revenue (' || total_revenue_generated || ')'
            when attributed_pipeline_value > total_pipeline_generated and attributed_pipeline_value is not null and total_pipeline_generated is not null then
                'Attributed pipeline (' || attributed_pipeline_value || ') > total pipeline (' || total_pipeline_generated || ')'
            when total_revenue_generated > total_pipeline_generated and total_revenue_generated is not null and total_pipeline_generated is not null then
                'Total revenue (' || total_revenue_generated || ') > total pipeline (' || total_pipeline_generated || ')'
            else null
        end as revenue_consistency_failure,
        
        case 
            -- Test 6: Cost validation
            when actual_cost < 0 then 'Negative actual cost: ' || actual_cost
            else null
        end as cost_validation_failure,
        
        case 
            -- Test 7: ROI calculation consistency (allowing for small floating point differences)
            when actual_cost is not null and actual_cost > 0 and total_revenue_generated is not null and roi_percentage is not null
                 and abs(roi_percentage - ((total_revenue_generated - actual_cost) / actual_cost * 100)) > 1.0 then
                'ROI calculation inconsistent. Expected: ' || ((total_revenue_generated - actual_cost) / actual_cost * 100) || ', Actual: ' || roi_percentage
            when actual_cost is not null and total_revenue_generated is not null and net_revenue is not null
                 and abs(net_revenue - (total_revenue_generated - actual_cost)) > 0.01 then
                'Net revenue calculation inconsistent. Expected: ' || (total_revenue_generated - actual_cost) || ', Actual: ' || net_revenue
            else null
        end as roi_calculation_failure
        
    from funnel_data
),

all_failures as (
    select 
        campaign_id,
        campaign_name,
        test_category,
        stage_progression_failure as failure_description
    from validation_failures
    where stage_progression_failure is not null
    
    union all
    
    select 
        campaign_id,
        campaign_name,
        'conversion_rates' as test_category,
        negative_conversion_rate_failure as failure_description
    from validation_failures
    where negative_conversion_rate_failure is not null
    
    union all
    
    select 
        campaign_id,
        campaign_name,
        'conversion_rates' as test_category,
        excessive_conversion_rate_failure as failure_description
    from validation_failures
    where excessive_conversion_rate_failure is not null
    
    union all
    
    select 
        campaign_id,
        campaign_name,
        'revenue_validation' as test_category,
        negative_revenue_failure as failure_description
    from validation_failures
    where negative_revenue_failure is not null
    
    union all
    
    select 
        campaign_id,
        campaign_name,
        'revenue_validation' as test_category,
        revenue_consistency_failure as failure_description
    from validation_failures
    where revenue_consistency_failure is not null
    
    union all
    
    select 
        campaign_id,
        campaign_name,
        'cost_validation' as test_category,
        cost_validation_failure as failure_description
    from validation_failures
    where cost_validation_failure is not null
    
    union all
    
    select 
        campaign_id,
        campaign_name,
        'roi_calculation' as test_category,
        roi_calculation_failure as failure_description
    from validation_failures
    where roi_calculation_failure is not null
)

-- Return all validation failures
-- If this query returns any rows, the test fails
select 
    campaign_id,
    campaign_name,
    test_category,
    failure_description,
    current_datetime() as test_run_at
from all_failures
order by campaign_name, test_category