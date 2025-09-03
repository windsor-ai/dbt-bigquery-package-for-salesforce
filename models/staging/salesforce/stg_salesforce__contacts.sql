{{ config(materialized='view') }}

with source as (
    select * from {{ source('salesforce', 'salesforce_contacts') }}
),

transformed as (
    select
        {{ var('contacts_id_field', 'contact_id') }} as id,
        {{ var('contacts_first_name_field', 'contact_firstname') }} as first_name,
        {{ var('contacts_last_name_field', 'contact_lastname') }} as last_name,
        {{ var('contacts_name_field', 'contact_name') }} as full_name,
        {{ var('contacts_salutation_field', 'contact_salutation') }} as salutation,
        
        {{ var('contacts_email_field', 'contact_email') }} as email,
        {{ var('contacts_phone_field', 'contact_phone') }} as phone,
        {{ var('contacts_mobile_phone_field', 'contact_mobilephone') }} as mobile_phone,
        {{ var('contacts_home_phone_field', 'contact_homephone') }} as home_phone,
        {{ var('contacts_other_phone_field', 'contact_otherphone') }} as other_phone,
        {{ var('contacts_fax_field', 'contact_fax') }} as fax,
        
        {{ var('contacts_title_field', 'contact_title') }} as title,
        {{ var('contacts_department_field', 'contact_department') }} as department,
        {{ var('contacts_lead_source_field', 'contact_leadsource') }} as lead_source,
        {{ var('contacts_description_field', 'contact_description') }} as description,
        
        -- Clean date conversions using SAFE_CAST
        safe_cast({{ var('contacts_created_date_field', 'contact_createddate') }} as timestamp) as created_at,
        safe_cast({{ var('contacts_last_modified_date_field', 'contact_lastmodifieddate') }} as timestamp) as last_modified_at,
        safe_cast({{ var('contacts_birthdate_field', 'contact_birthdate') }} as date) as birthdate,
        safe_cast({{ var('contacts_last_activity_date_field', 'contact_lastactivitydate') }} as date) as last_activity_date,
        safe_cast({{ var('contacts_last_referenced_date_field', 'contact_lastreferenceddatetime') }} as timestamp) as last_referenced_at,
        safe_cast({{ var('contacts_last_viewed_date_field', 'contact_lastvieweddate') }} as timestamp) as last_viewed_at,
        safe_cast({{ var('contacts_email_bounced_date_field', 'contact_emailbounceddate') }} as timestamp) as email_bounced_at,
        
        -- Account association
        {{ var('contacts_account_id_field', 'contact_accountid') }} as account_id,
        
        -- Clean boolean conversion
        safe_cast({{ var('contacts_is_email_bounced_field', 'contact_isemailbounced') }} as boolean) as is_email_bounced,
        {{ var('contacts_email_bounced_reason_field', 'contact_emailbouncedreason') }} as email_bounced_reason,
        
        -- Mailing address fields
        {{ var('contacts_mailing_street_field', 'contact_mailingstreet') }} as mailing_street,
        {{ var('contacts_mailing_city_field', 'contact_mailingcity') }} as mailing_city,
        {{ var('contacts_mailing_state_field', 'contact_mailingstate') }} as mailing_state,
        {{ var('contacts_mailing_postal_code_field', 'contact_mailingpostalcode') }} as mailing_postal_code,
        {{ var('contacts_mailing_country_field', 'contact_mailingcountry') }} as mailing_country,
        
        -- Other address fields
        {{ var('contacts_other_street_field', 'contact_otherstreet') }} as other_street,
        {{ var('contacts_other_city_field', 'contact_othercity') }} as other_city,
        {{ var('contacts_other_state_field', 'contact_otherstate') }} as other_state,
        {{ var('contacts_other_postal_code_field', 'contact_otherpostalcode') }} as other_postal_code,
        {{ var('contacts_other_country_field', 'contact_othercountry') }} as other_country,
        
        -- Other useful fields
        {{ var('contacts_owner_id_field', 'contact_ownerid') }} as owner_id,
        {{ var('contacts_reports_to_id_field', 'contact_reportstoid') }} as reports_to_id,
        {{ var('contacts_assistant_name_field', 'contact_assistantname') }} as assistant_name,
        {{ var('contacts_assistant_phone_field', 'contact_assistantphone') }} as assistant_phone,
        {{ var('contacts_created_by_field', 'contact_createdby') }} as created_by,
        
        -- Custom fields
        {{ var('contacts_languages_field', 'contact_wsai__languages__c') }} as languages,
        {{ var('contacts_level_field', 'contact_wsai__level__c') }} as level,
        
        -- System field
        {{ var('contacts_date_field', 'contact_date') }} as date_field
        
    from source
    where lower({{ var('contacts_is_deleted_field', 'contact_isdeleted') }}) = 'false'
)

select * from transformed