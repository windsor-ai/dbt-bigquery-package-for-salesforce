{{ config(materialized='view') }}

with leads_base as (
    select 
        id as lead_id,
        first_name,
        last_name,
        full_name,
        email,
        company,
        title,
        phone,
        status as lead_status,
        source as lead_source,
        rating,
        created_at as lead_created_at,
        converted_date,
        converted_contact_id,
        converted_opportunity_id,
        converted_account_id,
        is_converted,
        days_to_conversion,
        owner_id as lead_owner_id
    from {{ ref('stg_salesforce__leads') }}
),

campaign_touchpoints as (
    select 
        cm.lead_id,
        cm.campaign_id,
        cm.id as campaign_member_id,
        cm.status as campaign_member_status,
        cm.has_responded,
        cm.first_responded_date,
        cm.days_to_response,
        cm.created_at as campaign_member_created_at,
        c.name as campaign_name,
        c.type as campaign_type,
        c.status as campaign_status,
        c.actual_cost as campaign_cost,
        row_number() over (partition by cm.lead_id order by cm.created_at) as campaign_touch_sequence,
        count(*) over (partition by cm.lead_id) as total_campaign_touches
    from {{ ref('stg_salesforce__campaign_members') }} cm
    inner join {{ ref('stg_salesforce__campaigns') }} c on cm.campaign_id = c.id
    where cm.member_type = 'Lead'
      and cm.lead_id is not null
),

converted_contacts as (
    select 
        id as contact_id,
        first_name as contact_first_name,
        last_name as contact_last_name,
        full_name as contact_full_name,
        email as contact_email,
        created_at as contact_created_at,
        owner_id as contact_owner_id
    from {{ ref('stg_salesforce__contacts') }}
),

resulting_opportunities as (
    select 
        o.id as opportunity_id,
        o.name as opportunity_name,
        o.campaign_id as opportunity_primary_campaign_id,
        o.contact_id,
        o.stage_name,
        o.is_closed,
        o.is_won,
        o.amount,
        o.probability,
        o.expected_revenue,
        o.created_at as opportunity_created_at,
        o.close_date,
        o.sales_cycle_days,
        o.owner_id as opportunity_owner_id
    from {{ ref('stg_salesforce__opportunities') }} o
),

lead_journey_base as (
    select 
        l.lead_id,
        l.first_name,
        l.last_name,
        l.full_name,
        l.email,
        l.company,
        l.title,
        l.phone,
        l.lead_status,
        l.lead_source,
        l.rating,
        l.lead_owner_id,
        
        -- Lead lifecycle dates
        l.lead_created_at,
        l.converted_date,
        l.is_converted,
        l.days_to_conversion,
        
        -- Campaign touchpoint info (first touch)
        ct_first.campaign_id as first_touch_campaign_id,
        ct_first.campaign_name as first_touch_campaign_name,
        ct_first.campaign_type as first_touch_campaign_type,
        ct_first.campaign_member_created_at as first_campaign_touch_at,
        ct_first.has_responded as first_touch_responded,
        ct_first.first_responded_date as first_touch_response_date,
        
        -- Campaign touchpoint info (last touch)
        ct_last.campaign_id as last_touch_campaign_id,
        ct_last.campaign_name as last_touch_campaign_name,
        ct_last.campaign_type as last_touch_campaign_type,
        ct_last.campaign_member_created_at as last_campaign_touch_at,
        ct_last.has_responded as last_touch_responded,
        ct_last.first_responded_date as last_touch_response_date,
        
        -- Campaign summary
        ct_first.total_campaign_touches,
        
        -- Converted contact info
        l.converted_contact_id,
        cc.contact_first_name,
        cc.contact_last_name,
        cc.contact_full_name,
        cc.contact_email,
        cc.contact_created_at,
        cc.contact_owner_id,
        
        -- Resulting opportunity info
        l.converted_opportunity_id,
        o.opportunity_name,
        o.opportunity_primary_campaign_id,
        o.stage_name as opportunity_stage,
        o.is_closed as opportunity_is_closed,
        o.is_won as opportunity_is_won,
        o.amount as opportunity_amount,
        o.probability as opportunity_probability,
        o.expected_revenue as opportunity_expected_revenue,
        o.opportunity_created_at,
        o.close_date as opportunity_close_date,
        o.sales_cycle_days as opportunity_sales_cycle_days,
        o.opportunity_owner_id
        
    from leads_base l
    left join campaign_touchpoints ct_first 
        on l.lead_id = ct_first.lead_id 
        and ct_first.campaign_touch_sequence = 1
    left join campaign_touchpoints ct_last 
        on l.lead_id = ct_last.lead_id 
        and ct_last.campaign_touch_sequence = ct_last.total_campaign_touches
    left join converted_contacts cc 
        on l.converted_contact_id = cc.contact_id
    left join resulting_opportunities o 
        on l.converted_opportunity_id = o.opportunity_id
),

final as (
    select 
        lead_id,
        first_name,
        last_name,
        full_name,
        email,
        company,
        title,
        phone,
        lead_status,
        lead_source,
        rating,
        lead_owner_id,
        
        -- Funnel Stage Tracking
        case 
            when lead_created_at is not null then 'Lead Created'
            else null
        end as stage_1_lead_created,
        
        case 
            when first_campaign_touch_at is not null then 'Campaign Member Added'
            else null
        end as stage_2_campaign_member_added,
        
        case 
            when first_touch_responded = true then 'Lead Responded'
            else null
        end as stage_3_lead_responded,
        
        case 
            when is_converted = true then 'Lead Converted to Contact'
            else null
        end as stage_4_lead_converted,
        
        case 
            when opportunity_created_at is not null then 'Opportunity Created'
            else null
        end as stage_5_opportunity_created,
        
        case 
            when opportunity_is_won = true then 'Opportunity Won'
            when opportunity_is_closed = true and opportunity_is_won = false then 'Opportunity Lost'
            else null
        end as stage_6_opportunity_outcome,
        
        -- Lifecycle dates
        lead_created_at,
        first_campaign_touch_at,
        first_touch_response_date,
        converted_date,
        opportunity_created_at,
        opportunity_close_date,
        
        -- Timing metrics
        case 
            when first_campaign_touch_at is not null and lead_created_at is not null
            then date_diff(date(first_campaign_touch_at), date(lead_created_at), day)
            else null
        end as days_lead_to_campaign,
        
        case 
            when converted_date is not null and first_campaign_touch_at is not null
            then date_diff(date(converted_date), date(first_campaign_touch_at), day)
            else null
        end as days_campaign_to_conversion,
        
        case 
            when opportunity_created_at is not null and converted_date is not null
            then date_diff(date(opportunity_created_at), date(converted_date), day)
            else null
        end as days_conversion_to_opportunity,
        
        -- Campaign attribution
        first_touch_campaign_id,
        first_touch_campaign_name,
        first_touch_campaign_type,
        first_touch_responded,
        last_touch_campaign_id,
        last_touch_campaign_name,
        last_touch_campaign_type,
        last_touch_responded,
        total_campaign_touches,
        
        -- Attribution credit calculation for multi-touch attribution
        case 
            when total_campaign_touches = 1 then 1.0
            when total_campaign_touches > 1 then round(1.0 / total_campaign_touches, 3)
            else null
        end as attribution_credit,
        
        -- Conversion status
        is_converted,
        days_to_conversion,
        
        -- Contact details
        converted_contact_id,
        contact_first_name,
        contact_last_name,
        contact_full_name,
        contact_email,
        contact_created_at,
        contact_owner_id,
        
        -- Opportunity details
        converted_opportunity_id,
        opportunity_name,
        opportunity_primary_campaign_id,
        opportunity_stage,
        opportunity_is_closed,
        opportunity_is_won,
        opportunity_amount,
        opportunity_probability,
        opportunity_expected_revenue,
        opportunity_sales_cycle_days,
        opportunity_owner_id,
        
        -- Overall journey metrics
        case 
            when opportunity_close_date is not null and lead_created_at is not null
            then date_diff(date(opportunity_close_date), date(lead_created_at), day)
            else null
        end as total_journey_days,
        
        -- Journey completeness score (0-1)
        case
            when opportunity_is_won = true then 1.0
            else round(
                (case when lead_created_at is not null then 1.0/6 else 0 end +
                case when first_campaign_touch_at is not null then 1.0/6 else 0 end +
                case when first_touch_responded = true then 1.0/6 else 0 end +
                case when is_converted = true then 1.0/6 else 0 end +
                case when opportunity_created_at is not null then 1.0/6 else 0 end +
                case when opportunity_is_closed = true then 1.0/6 else 0 end), 3
            )
        end as journey_completeness_score
        
    from lead_journey_base
    where 
        -- Exclude leads with orphaned converted_contact_id references
        (converted_contact_id is null or (converted_contact_id is not null and contact_first_name is not null))
)

select * from final