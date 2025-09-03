{{ config(materialized='view') }}

with source as (
    select * from {{ source('salesforce', 'salesforce_campaign_members') }}
),

transformed as (
    select
        {{ var('campaign_members_id_field', 'campaignmember_id') }} as id,
        {{ var('campaign_members_campaign_id_field', 'campaignmember_campaign_id') }} as campaign_id,
        {{ var('campaign_members_lead_id_field', 'campaignmember_lead_id') }} as lead_id,
        {{ var('campaign_members_contact_id_field', 'campaignmember_contact_id') }} as contact_id,
        {{ var('campaign_members_lead_or_contact_id_field', 'campaignmember_lead_or_contact_id') }} as lead_or_contact_id,
        
        -- Determine member_type as 'Lead' or 'Contact' based on which ID is populated
        case 
            when {{ var('campaign_members_lead_id_field', 'campaignmember_lead_id') }} is not null then 'Lead'
            when {{ var('campaign_members_contact_id_field', 'campaignmember_contact_id') }} is not null then 'Contact'
            else {{ var('campaign_members_type_field', 'campaignmember_type') }}
        end as member_type,
        
        {{ var('campaign_members_first_name_field', 'campaignmember_first_name') }} as first_name,
        {{ var('campaign_members_last_name_field', 'campaignmember_last_name') }} as last_name,
        {{ var('campaign_members_name_field', 'campaignmember_name') }} as full_name,
        {{ var('campaign_members_salutation_field', 'campaignmember_salutation') }} as salutation,
        
        {{ var('campaign_members_company_or_account_field', 'campaignmember_company_or_account') }} as company_or_account,
        {{ var('campaign_members_title_field', 'campaignmember_title') }} as title,
        {{ var('campaign_members_phone_field', 'campaignmember_phone') }} as phone,
        {{ var('campaign_members_fax_field', 'campaignmember_fax') }} as fax,
        {{ var('campaign_members_lead_source_field', 'campaignmember_lead_source') }} as lead_source,
        {{ var('campaign_members_description_field', 'campaignmember_description') }} as description,
        
        -- Date fields using utility macros
        {{ safe_date_parse(var('campaign_members_created_date_field', 'campaignmember_createddate'), 'timestamp') }} as created_at,
        {{ safe_date_parse(var('campaign_members_last_modified_date_field', 'campaignmember_lastmodifieddate'), 'timestamp') }} as last_modified_at,
        {{ safe_date_parse(var('campaign_members_first_responded_date_field', 'campaignmember_first_responded_date'), 'timestamp') }} as first_responded_date,
        
        -- Convert string boolean to actual boolean using utility macro
        -- Ensure has_responded is false if first_responded_date is null
        case 
            when {{ safe_date_parse(var('campaign_members_first_responded_date_field', 'campaignmember_first_responded_date'), 'timestamp') }} is null then false
            else {{ clean_boolean(var('campaign_members_has_responded_field', 'campaignmember_has_responded')) }}
        end as has_responded,
        
        {{ var('campaign_members_status_field', 'campaignmember_status') }} as status,
        
        -- Calculate days_to_response using utility macro
        {{ calculate_days_between(var('campaign_members_created_date_field', 'campaignmember_createddate'), var('campaign_members_first_responded_date_field', 'campaignmember_first_responded_date')) }} as days_to_response,
        
        -- Address fields
        {{ var('campaign_members_street_field', 'campaignmember_street') }} as street,
        {{ var('campaign_members_postal_code_field', 'campaignmember_postal_code') }} as postal_code,
        {{ var('campaign_members_state_field', 'campaignmember_state') }} as state,
        {{ var('campaign_members_country_field', 'campaignmember_country') }} as country,
        
        -- Convert string boolean fields using utility macro
        {{ clean_boolean(var('campaign_members_do_not_call_field', 'campaignmember_do_not_call')) }} as do_not_call,
        {{ clean_boolean(var('campaign_members_has_opted_out_of_fax_field', 'campaignmember_has_opted_out_of_fax')) }} as has_opted_out_of_fax,
        
        -- Owner tracking
        {{ var('campaign_members_lead_or_contact_owner_id_field', 'campaignmember_lead_or_contact_owner_id') }} as lead_or_contact_owner_id

    from source
)

-- Filter out records with orphaned campaign_id references
select t.* 
from transformed t
where t.campaign_id in (select id from {{ ref('stg_salesforce__campaigns') }})