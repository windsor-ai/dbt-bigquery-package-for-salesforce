{{ config(materialized='view') }}

with source as (
    select * from {{ source('salesforce', 'salesforce_opportunities') }}
),

transformed as (
    select
        {{ var('opportunities_id_field', 'opportunity_id') }} as id,
        {{ var('opportunities_name_field', 'opportunity_name') }} as name,
        {{ var('opportunities_description_field', 'opportunity_description') }} as description,
        {{ var('opportunities_type_field', 'opportunity_type') }} as type,
        
        -- Links to primary campaign source via campaign_id
        {{ var('opportunities_campaign_id_field', 'opportunity_campaign_id') }} as campaign_id,
        
        -- Account and contact associations
        {{ var('opportunities_account_id_field', 'opportunity_account_id') }} as account_id,
        {{ var('opportunities_contact_id_field', 'opportunity_contact_id') }} as contact_id,
        
        -- Stage progression and win/loss status
        {{ var('opportunities_stage_name_field', 'opportunity_stage_name') }} as stage_name,
        {{ var('opportunities_forecast_category_field', 'opportunity_forecast_category') }} as forecast_category,
        {{ var('opportunities_forecast_category_name_field', 'opportunity_forecast_category_name') }} as forecast_category_name,
        
        -- Clean boolean conversions using SAFE_CAST
        safe_cast({{ var('opportunities_is_closed_field', 'opportunity_is_closed') }} as boolean) as is_closed,
        safe_cast({{ var('opportunities_is_won_field', 'opportunity_is_won') }} as boolean) as is_won,
        
        -- Financial fields - includes expected_revenue and amount fields
        safe_cast({{ var('opportunities_amount_field', 'opportunity_amount') }} as numeric) as amount,
        safe_cast({{ var('opportunities_probability_field', 'opportunity_probability') }} as numeric) as probability,
        
        -- Calculate expected_revenue as amount * probability
        case 
            when safe_cast({{ var('opportunities_amount_field', 'opportunity_amount') }} as numeric) is not null 
                and safe_cast({{ var('opportunities_probability_field', 'opportunity_probability') }} as numeric) is not null
            then safe_cast({{ var('opportunities_amount_field', 'opportunity_amount') }} as numeric) * (safe_cast({{ var('opportunities_probability_field', 'opportunity_probability') }} as numeric) / 100)
            else null
        end as expected_revenue,
        
        -- Clean date conversions using SAFE_CAST
        coalesce(
            safe_cast({{ var('opportunities_created_date_field', 'opportunity_created_date') }} as timestamp),
            safe_cast({{ var('opportunities_created_date_fallback_field', 'opportunity_createddate') }} as timestamp)
        ) as created_at,
        
        safe_cast({{ var('opportunities_close_date_field', 'opportunity_close_date') }} as date) as close_date,
        
        coalesce(
            safe_cast({{ var('opportunities_last_modified_date_field', 'opportunity_last_modified_date') }} as timestamp),
            safe_cast({{ var('opportunities_last_modified_date_fallback_field', 'opportunity_lastmodifieddate') }} as timestamp)
        ) as last_modified_at,
        
        safe_cast({{ var('opportunities_last_activity_date_field', 'opportunity_last_activity_date') }} as date) as last_activity_date,
        safe_cast({{ var('opportunities_last_referenced_date_field', 'opportunity_last_referenced_date') }} as timestamp) as last_referenced_at,
        safe_cast({{ var('opportunities_last_viewed_date_field', 'opportunity_last_viewed_date') }} as timestamp) as last_viewed_at,
        
        -- Calculate sales_cycle_days using SAFE_CAST
        case 
            when safe_cast({{ var('opportunities_close_date_field', 'opportunity_close_date') }} as date) is not null
                and coalesce(
                    safe_cast({{ var('opportunities_created_date_field', 'opportunity_created_date') }} as timestamp),
                    safe_cast({{ var('opportunities_created_date_fallback_field', 'opportunity_createddate') }} as timestamp)
                ) is not null
            then date_diff(
                safe_cast({{ var('opportunities_close_date_field', 'opportunity_close_date') }} as date),
                date(coalesce(
                    safe_cast({{ var('opportunities_created_date_field', 'opportunity_created_date') }} as timestamp),
                    safe_cast({{ var('opportunities_created_date_fallback_field', 'opportunity_createddate') }} as timestamp)
                )),
                day
            )
            else null
        end as sales_cycle_days,
        
        -- Fiscal period fields
        {{ var('opportunities_fiscal_field', 'opportunity_fiscal') }} as fiscal_period,
        safe_cast({{ var('opportunities_fiscal_quarter_field', 'opportunity_fiscal_quarter') }} as integer) as fiscal_quarter,
        safe_cast({{ var('opportunities_fiscal_year_field', 'opportunity_fiscal_year') }} as integer) as fiscal_year,
        
        -- Activity tracking - clean boolean conversions
        safe_cast({{ var('opportunities_has_open_activity_field', 'opportunity_has_open_activity') }} as boolean) as has_open_activity,
        safe_cast({{ var('opportunities_has_opportunity_line_item_field', 'opportunity_has_opportunity_line_item') }} as boolean) as has_opportunity_line_item,
        safe_cast({{ var('opportunities_has_overdue_task_field', 'opportunity_has_overdue_task') }} as boolean) as has_overdue_task,
        
        -- Lead source
        {{ var('opportunities_lead_source_field', 'opportunity_lead_source') }} as lead_source,
        
        -- Process fields
        {{ var('opportunities_next_step_field', 'opportunity_next_step') }} as next_step,
        
        -- Owner and system fields
        {{ var('opportunities_owner_id_field', 'opportunity_owner_id') }} as owner_id,
        {{ var('opportunities_created_by_id_field', 'opportunity_created_by_id') }} as created_by_id,
        {{ var('opportunities_last_modified_by_id_field', 'opportunity_last_modified_by_id') }} as last_modified_by_id,
        {{ var('opportunities_pricebook_id_field', 'opportunity_pricebook2_id') }} as pricebook_id,
        {{ var('opportunities_system_modstamp_field', 'opportunity_system_modstamp') }} as system_modstamp,
        
        -- History tracking
        {{ var('opportunities_last_amount_changed_history_id_field', 'opportunity_last_amount_changed_history_id') }} as last_amount_changed_history_id,
        {{ var('opportunities_last_close_date_changed_history_id_field', 'opportunity_last_close_date_changed_history_id') }} as last_close_date_changed_history_id,
        
        -- Custom fields
        {{ var('opportunities_current_generators_field', 'opportunity_wsai__currentgenerators__c') }} as current_generators,
        {{ var('opportunities_delivery_installation_status_field', 'opportunity_wsai__deliveryinstallationstatus__c') }} as delivery_installation_status,
        {{ var('opportunities_main_competitors_field', 'opportunity_wsai__maincompetitors__c') }} as main_competitors,
        {{ var('opportunities_order_number_field', 'opportunity_wsai__ordernumber__c') }} as order_number,
        {{ var('opportunities_tracking_number_field', 'opportunity_wsai__trackingnumber__c') }} as tracking_number

    from source
    where ({{ var('opportunities_is_deleted_field', 'opportunity_is_deleted') }} = 'false' 
       OR {{ var('opportunities_is_deleted_field', 'opportunity_is_deleted') }} IS NULL)
)

select * from transformed