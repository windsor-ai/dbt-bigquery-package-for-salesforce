{{ config(materialized='view') }}

with source as (
    select * from {{ source('salesforce', 'salesforce_campaigns') }}
),

transformed as (
    select
        {{ var('campaigns_id_field', 'campaign_id') }} as id,
        {{ var('campaigns_name_field', 'campaign_name') }} as name,
        {{ var('campaigns_type_field', 'campaign_type') }} as type,
        {{ var('campaigns_status_field', 'campaign_status') }} as status,
        
        {{ var('campaigns_description_field', 'campaign_description') }} as description,
        
        -- Convert STRING date fields to proper types using utility macros
        {{ safe_date_parse(var('campaigns_created_date_field', 'campaign_created_date')) }} as created_at,
        {{ parse_date_with_format(var('campaigns_start_date_field', 'campaign_start_date')) }} as start_date,
        {{ parse_date_with_format(var('campaigns_end_date_field', 'campaign_end_date')) }} as end_date,
        
        -- Convert string boolean to actual boolean using utility macro
        {{ clean_boolean(var('campaigns_is_active_field', 'campaign_is_active')) }} as is_active,
        
        -- Cast numeric fields appropriately using utility macro
        {{ clean_currency(var('campaigns_actual_cost_field', 'campaign_actual_cost'), 0) }} as actual_cost,
        {{ clean_currency(var('campaigns_budgeted_cost_field', 'campaign_budgeted_cost'), 0) }} as budgeted_cost,
        {{ clean_currency(var('campaigns_expected_revenue_field', 'campaign_expected_revenue'), 0) }} as expected_revenue,
        {{ clean_currency(var('campaigns_expected_response_field', 'campaign_expected_response'), 0) }} as expected_response,
        {{ clean_currency(var('campaigns_number_sent_field', 'campaign_number_sent'), 0) }} as number_sent,
        
        -- Calculate campaign duration in days using utility macro
        {{ calculate_days_between(var('campaigns_start_date_field', 'campaign_start_date'), var('campaigns_end_date_field', 'campaign_end_date')) }} as campaign_duration_days,
        
        -- Aggregated fields using utility macro
        {{ clean_currency(var('campaigns_number_of_leads_field', 'campaign_number_of_leads'), 0) }} as number_of_leads,
        {{ clean_currency(var('campaigns_number_of_converted_leads_field', 'campaign_number_of_converted_leads'), 0) }} as number_of_converted_leads,
        {{ clean_currency(var('campaigns_number_of_contacts_field', 'campaign_number_of_contacts'), 0) }} as number_of_contacts,
        {{ clean_currency(var('campaigns_number_of_opportunities_field', 'campaign_number_of_opportunities'), 0) }} as number_of_opportunities,
        {{ clean_currency(var('campaigns_number_of_won_opportunities_field', 'campaign_number_of_won_opportunities'), 0) }} as number_of_won_opportunities,
        {{ clean_currency(var('campaigns_amount_all_opportunities_field', 'campaign_amount_all_opportunities'), 0) }} as amount_all_opportunities,
        {{ clean_currency(var('campaigns_amount_won_opportunities_field', 'campaign_amount_won_opportunities'), 0) }} as amount_won_opportunities,
        
        -- Include other useful fields
        {{ var('campaigns_owner_id_field', 'campaign_owner_id') }} as owner_id,
        {{ var('campaigns_parent_id_field', 'campaign_parent_id') }} as parent_id,

    from source
    where lower({{ var('campaigns_is_deleted_field', 'campaign_is_deleted') }}) = 'false'
)

select * from transformed