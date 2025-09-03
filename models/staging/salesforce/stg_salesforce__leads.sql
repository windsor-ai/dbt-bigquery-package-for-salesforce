{{ config(materialized='view') }}

with source as (
    select * from {{ source('salesforce', 'salesforce_leads') }}
),

transformed as (
    select
        {{ var('leads_id_field', 'lead_id') }} as id,
        {{ var('leads_first_name_field', 'lead_first_name') }} as first_name,
        {{ var('leads_last_name_field', 'lead_last_name') }} as last_name,
        {{ var('leads_name_field', 'lead_name') }} as full_name,
        
        -- Handle email field with fallback using utility macro
        {{ coalesce_email_fields(var('leads_email_field', 'lead_email'), var('leads_email_fallback_field', 'email')) }} as email,
        
        {{ var('leads_company_field', 'lead_company') }} as company,
        {{ var('leads_title_field', 'lead_title') }} as title,
        {{ clean_phone(var('leads_phone_field', 'lead_phone')) }} as phone,
        {{ var('leads_status_field', 'lead_status') }} as status,
        {{ var('leads_source_field', 'lead_lead_source') }} as source,
        {{ var('leads_rating_field', 'lead_rating') }} as rating,
        
        -- Convert STRING date fields to proper types using utility macro
        {{ safe_date_parse(var('leads_created_date_field', 'lead_created_date')) }} as created_at,
        
        -- Conversion tracking fields
        -- Replace converted_date parsing with direct SAFE_CAST:
        safe_cast({{ var('leads_converted_date_field', 'lead_converted_date') }} as timestamp) as converted_date,
        {{ var('leads_converted_contact_id_field', 'lead_converted_contact_id') }} as converted_contact_id,
        {{ var('leads_converted_opportunity_id_field', 'lead_converted_opportunity_id') }} as converted_opportunity_id,
        {{ var('leads_converted_account_id_field', 'lead_converted_account_id') }} as converted_account_id,
        
        -- Convert string boolean to actual boolean using utility macro
        case 
            when {{ var('leads_converted_contact_id_field', 'lead_converted_contact_id') }} is not null
              or lower({{ var('leads_status_field', 'lead_status') }}) = 'closed - converted'
            then true 
            else false 
        end as is_converted,
        
        -- Calculate days_to_conversion using utility macro
        {{ calculate_days_between(var('leads_created_date_field', 'lead_created_date'), var('leads_converted_date_field', 'lead_converted_date')) }} as days_to_conversion,
        
        -- Address fields
        {{ var('leads_street_field', 'lead_street') }} as street,
        {{ var('leads_city_field', 'lead_city') }} as city,
        {{ var('leads_state_field', 'lead_state') }} as state,
        {{ var('leads_postal_code_field', 'lead_postal_code') }} as postal_code,
        {{ var('leads_country_field', 'lead_country') }} as country,
        
        -- Other useful fields
        {{ var('leads_owner_id_field', 'lead_owner_id') }} as owner_id,
        {{ var('leads_industry_field', 'lead_industry') }} as industry,
        {{ clean_currency(var('leads_annual_revenue_field', 'lead_annual_revenue'), 0) }} as annual_revenue,
        {{ clean_currency(var('leads_number_of_employees_field', 'lead_number_of_employees'), 0) }} as number_of_employees,
        

    from source
    where lower({{ var('leads_is_deleted_field', 'lead_is_deleted') }}) = 'false'
)

select * from transformed