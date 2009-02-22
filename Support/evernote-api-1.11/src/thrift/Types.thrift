/*
 * Copyright (c) 2007-2008 by Evernote Corporation, All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.    
 */

/*
 * This file contains the definitions of the Evernote data model as it
 * is represented through the EDAM protocol.  This is the "client-independent"
 * view of the contents of a user's account.  Each client will translate the
 * neutral data model into an appropriate form for storage on that client.
 */

include "Limits.thrift"

namespace java com.evernote.edam.type
namespace csharp Evernote.EDAM.Type
namespace py evernote.edam.type
namespace cpp evernote.edam
namespace rb Evernote.EDAM.Type
php_namespace edam_type
namespace cocoa EDAM
namespace perl EDAMTypes


// =============================== typedefs ====================================

/**
 * Every Evernote account is assigned a unique numeric identifier which
 * will not change for the life of the account.  This is independent of
 * the (string-based) "username" which is known by the user for login
 * purposes.  The user should have no reason to know their UserID.
 */
typedef i32 UserID


/**
 * Most data elements within a user's account (e.g. notebooks, notes, tags,
 * resources, etc.) are internally referred to using a globally unique
 * identifier that is written in a standard string format.  For example:
 *
 *    "8743428c-ef91-4d05-9e7c-4a2e856e813a"
 *
 * The internal components of the GUID are not given any particular meaning:
 * only the entire string is relevant as a unique identifier.
 */
typedef string Guid


/**
 * An Evernote Timestamp is the date and time of an event in UTC time.
 * This is expressed as a specific number of milliseconds since the 
 * standard base "epoch" of:
 *
 *    January 1, 1970, 00:00:00 GMT
 *
 * NOTE:  the time is expressed at the resolution of milliseconds, but
 * the value is only precise to the level of seconds.   This means that
 * the last three (decimal) digits of the timestamp will be '000'.
 *
 * The Thrift IDL specification does not include a native date/time type,
 * so this value is used instead.
 */
typedef i64 Timestamp


// ============================= Enumerations ==================================

/**
 * This enumeration defines the possible permission levels for a user.
 * Free accounts will have a level of NORMAL and paid Premium accounts
 * will have a level of PREMIUM.
 */
enum PrivilegeLevel {
  NORMAL = 1,
  PREMIUM = 3,
  VIP = 7,
  ADMIN = 9
}


/**
 * Every search query is specified as a sequence of characters.
 * Currently, only the USER query format is supported.
 */
enum QueryFormat {
  USER = 1,
  SEXP = 2
}


/**
 * This enumeration defines the possible sort ordering for notes when
 * they are returned from a search result.
 */
enum NoteSortOrder {
  CREATED = 1,
  UPDATED = 2,
  RELEVANCE = 3,
  UPDATE_SEQUENCE_NUMBER = 4
}


/**
 * This enumeration defines the possible states of a premium account
 *
 * NONE:    the user has never attempted to become a premium subscriber
 *
 * PENDING: the user has requested a premium account but their charge has not
 *   been confirmed
 *
 * ACTIVE:  the user has been charged and their premium account is in good
 *  standing
 *
 * FAILED:  the system attempted to charge the was denied. Their premium
 *   privileges have been revoked. We will periodically attempt to re-validate
 *   their order.
 *
 * CANCELLATION_PENDING: the user has requested that no further charges be made
 *   but the current account is still active.
 *
 * CANCELED: the premium account was canceled either because of failure to pay
 *   or user cancelation. No more attempts will be made to activate the account.
 */
enum PremiumOrderStatus {
  NONE                 = 0,
  PENDING              = 1,
  ACTIVE               = 2,
  FAILED               = 3,
  CANCELLATION_PENDING = 4,
  CANCELED             = 5
}

/**
 * Standardized value for the 'source' NoteAttribute for notes that
 * were clipped from the web in some manner.
 */
const string EDAM_NOTE_SOURCE_WEB_CLIP = "web.clip";

/**
 * Standardized value for the 'source' NoteAttribute for notes that
 * were clipped from an email message.
 */
const string EDAM_NOTE_SOURCE_MAIL_CLIP = "mail.clip";

/**
 * Standardized value for the 'source' NoteAttribute for notes that
 * were created via email sent to Evernote's email interface.
 */
const string EDAM_NOTE_SOURCE_MAIL_SMTP_GATEWAY = "mail.smtp";


// ============================== Structures ===================================

/**
 * In several places, EDAM exchanges blocks of bytes of data for a component
 * which may be relatively large.  For example:  the contents of a clipped
 * HTML note, the bytes of an embedded image, or the recognition XML for
 * a large image.  This structure is used in the protocol to represent
 * any of those large blocks of data when they are transmitted or when
 * they are only referenced their metadata.
 *
 *<dl>
 * <dt>bodyHash</dt>
 *   <dd>This field carries a one-way hash of the contents of the 
 *   data body, in binary form.  The hash function is MD5<br/>
 *   Length:  EDAM_HASH_LEN (exactly)
 *   </dd>
 *
 * <dt>size</dt>
 *   <dd>The length, in bytes, of the data body.
 *   </dd>
 *
 * <dt>body</dt>
 *   <dd>This field is set to contain the binary contents of the data
 *   whenever the resource is being transferred.  If only metadata is
 *   being exchanged, this field will be empty.  For example, a client could
 *   notify the service about the change to an attribute for a resource
 *   without transmitting the binary resource contents.
 *   </dd>
 * </dl>
 */
struct Data {
  1:  required  binary bodyHash,
  2:  required  i32 size,
  3:  optional  binary body
}


/**
 * A structure holding the optional attributes that can be stored
 * on a User.  These are generally less critical than the core User fields.
 *
 *<dl>
 * <dt>defaultLocationName</dt>
 *   <dd>the location string that should be associated
 *   with the user in order to determine where notes are taken if not otherwise
 *   specified.<br/>
 *   Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>defaultLatitude</dt>
 *   <dd>if set, this is the latitude that should be
 *   assigned to any notes that have no other latitude information.
 *   </dd>
 *
 * <dt>defaultLongitude</dt>
 *   <dd>if set, this is the longitude that should be
 *   assigned to any notes that have no other longitude information.
 *   </dd>
 *
 * <dt>preactivation</dt>
 *   <dd>if set, the user account is not yet confirmed for
 *   login.  I.e. the account has been created, but we are still waiting for
 *   the user to complete the activation step.
 *   </dd>
 *
 * <dt>viewedPromotions</dt>
 *   <dd>a list of promotions the user has seen.
 *    This list may occasionally be modified by the system when promotions are
 *    no longer available.<br/>
 *    Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>incomingEmailAddress</dt>
 *   <dd>if set, this is the email address that the
 *    user may send email to in order to add an email note directly into the
 *    account via the SMTP email gateway.  This is the part of the email
 *    address before the '@' symbol ... our domain is not included.
 *    If this is not set, the user may not add notes via the gateway.<br/>
 *    Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>recentMailedAddresses</dt>
 *   <dd>if set, this will contain a list of email
 *    addresses that have recently been used as recipients
 *    of outbound emails by the user.  This can be used to pre-populate a
 *    list of possible destinations when a user wishes to send a note via
 *    email.<br/>
 *    Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX each<br/>
 *    Max:  EDAM_USER_RECENT_MAILED_ADDRESSES_MAX entries
 *   </dd>
 *
 * <dt>comments</dt>
 *   <dd>Free-form text field that may hold general support
 *    information, etc.<br/>
 *    Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>dateAgreedToTermsOfService</dt>
 *   <dd>The date/time when the user agreed to
 *    the terms of service.  This can be used as the effective "start date"
 *    for the account.
 *   </dd>
 *
 * <dt>maxReferrals</dt>
 *   <dd>The number of referrals that the user is permitted
 *    to make.
 *   </dd>
 *
 * <dt>referralCount</dt>
 *   <dd>The number of referrals sent from this account.
 *   </dd>
 *
 * <dt>refererCode</dt>
 *   <dd>A code indicating where the user was sent from. AKA 
 *    promotion code
 *   </dd>
 *    
 * <dt>sentEmailDate</dt>
 *   <dd>The most recent date when the user sent outbound
 *    emails from the service.  Used with sentEmailCount to limit the number
 *    of emails that can be sent per day.
 *   </dd>
 *    
 * <dt>sentEmailCount</dt>
 *   <dd>The number of emails that were sent from the user
 *    via the service on sentEmailDate.  Used to enforce a limit on the number
 *    of emails per user per day to prevent spamming.
 *   </dd>
 *
 * <dt>dailyEmailLimit</dt>
 *   <dd>If set, this is the maximum number of emails that
 *    may be sent in a given day from this account.  If unset, the server will
 *    use the configured default limit.
 *   </dd>
 *
 * <dt>emailOptOutDate</dt>
 *   <dd>If set, this is the date when the user asked
 *    to be excluded from offers and promotions sent by Evernote.  If not set,
 *    then the user currently agrees to receive these messages.
 *   </dd>
 *
 * <dt>partnerEmailOptInDate</dt>
 *   <dd>If set, this is the date when the user asked
 *    to be included in offers and promotions sent by Evernote's partners.
 *    If not sent, then the user currently does not agree to receive these
 *    emails.
 *   </dd>
 *    
 * </dl>
 */
struct UserAttributes {
  1:  optional  string defaultLocationName,
  2:  optional  double defaultLatitude,
  3:  optional  double defaultLongitude,
  4:  optional  bool preactivation,
  5:  optional  list<string> viewedPromotions,
  6:  optional  string incomingEmailAddress,
  7:  optional  list<string> recentMailedAddresses,
  9:  optional  string comments,
  11: optional  Timestamp dateAgreedToTermsOfService,
  12: optional  i32 maxReferrals,
  13: optional  i32 referralCount,
  14: optional  string refererCode,
  15: optional  Timestamp sentEmailDate,
  16: optional  i32 sentEmailCount,
  17: optional  i32 dailyEmailLimit,
  18: optional  Timestamp emailOptOutDate,
  19: optional  Timestamp partnerEmailOptInDate,
  20: optional  string preferredLanguage,
  21: optional  string preferredCountry
}

/**
 * This represents the bookkeeping information for the user's subscription.
 * 
 *<dl>
 * <dt>uploadLimit</dt>
 *   <dd>The number of bytes that can be uploaded to the account
 *   in the current month.  For new notes that are created, this is the length
 *   of the note content (in Unicode characters) plus the size of each resource
 *   (in bytes).  For edited notes, this is the the difference between the old
 *   length and the new length (if this is greater than 0) plus the size of
 *   each new resource.
 *   </dd>
 * <dt>uploadLimitEnd</dt>
 *   <dd>The date and time when the current upload limit
 *   expires.  At this time, the monthly upload count reverts to 0 and a new
 *   limit is imposed.  This date and time is exclusive, so this is effectively
 *   the start of the new month.
 *   </dd>
 * <dt>uploadLimitNextMonth</dt>
 *   <dd> When uploadLimitEnd is research the service
 *   will change uploadLimit to uploadLimitNextMonth. If a premium account is
 *   canceled, this mechanism will reset the quota appropriately.
 *   </dd>
 * <dt>premiumServiceStatus</dt>
 *   <dd>Indicates the phases of a premium account
 *   during the billing process.
 *   </dd>
 * <dt>premiumOrderNumber</dt>
 *   <dd>The order number used by the commerce system to
 *   process recurring payments
 *   </dd>
 * <dt>premiumServiceStart</dt>
 *   <dd>The start date when this premium promotion 
 *   began (this number will get overwritten if a premium service is canceled
 *   and then re-activated). 
 *   </dd>
 * <dt>premiumCommerceService</dt>
 *   <dd>The commerce system used (paypal, Google
 *   checkout, etc)
 *   </dd>
 * <dt>premiumServiceSKU</dt>
 *   <dd>The code associated with the purchase eg. monthly 
 *   or annual purchase. Clients should interpret this value and localize it.
 *   </dd>
 * <dt>lastSuccessfulCharge</dt>
 *   <dd>Date the last time the user was charged. 
 *   Null if never charged.
 *   </dd>
 * <dt>lastFailedCharge</dt>
 *   <dd>Date the last time a charge was attempted and
 *   failed.
 *   </dd>
 * <dt>lastFailedChargeReason</dt>
 *   <dd>Reason provided for the charge failure
 *   </dd>
 * <dt>nextPaymentDue</dt>
 *   <dd>The end of the billing cycle. This could be in the 
 *   past if there are failed charges.
 *   </dd>
 * <dt>premiumLockUntil</dt>
 *   <dd>An internal variable to manage locking operations 
 *   on the commerce variables.
 *   </dd>
 * <dt>updated</dt>
 *   <dd>The date any modification where made to this record.
 *   </dd>
 * <dt>premiumSubscriptionNumber</dt>
 *   <dd>The number number identifying the
 *   recurring subscription used to make the recurring charges.
 *   </dd>
 * </dl>
 */
struct Accounting {
  1:  required  i64        uploadLimit,
  2:  required  Timestamp  uploadLimitEnd,
  3:  required  i64        uploadLimitNextMonth,
  4:  required  PremiumOrderStatus premiumServiceStatus,
  5:  optional  string     premiumOrderNumber,
  6:  optional  string     premiumCommerceService,
  7:  optional  Timestamp  premiumServiceStart,
  8:  optional  string     premiumServiceSKU,
  9:  optional  Timestamp  lastSuccessfulCharge,
  10: optional  Timestamp  lastFailedCharge,
  11: optional  string     lastFailedChargeReason,
  12: optional  Timestamp  nextPaymentDue,
  13: optional  Timestamp  premiumLockUntil,
  14: optional  Timestamp  updated,
  16: optional  string     premiumSubscriptionNumber,
}


/**
 * This represents the information about a single user account.
 *<dl>
 * <dt>id</dt>
 *   <dd>The unique numeric identifier for the account, which will not
 *   change for the lifetime of the account.
 *   </dd>
 *
 * <dt>username</dt>
 *   <dd>The name that the user provides to log in to their
 *   account. In the future, this may be empty for some accounts if their login
 *   process is indirect (e.g. via social networks, etc.).
 *   May only contain a-z, 0-9, or '-', and may not start or end with the '-'
 *   <br/>
 *   Length:  EDAM_USER_USERNAME_LEN_MIN - EDAM_USER_USERNAME_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_USER_USERNAME_REGEX
 *   </dd>
 *
 * <dt>email</dt>
 *   <dd>The email address registered for the user.  Must comply with
 *   RFC 2821 and RFC 2822.<br/>
 *   Length:  EDAM_EMAIL_LEN_MIN - EDAM_EMAIL_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_EMAIL_REGEX
 *   </dd>
 *
 * <dt>name</dt>
 *   <dd>The printable name of the user, which may be a combination
 *   of given and family names.  This is used instead of separate "first"
 *   and "last" names due to variations in international name format/order.
 *   May not start or end with a whitespace character.  May contain any
 *   character but carriage return or newline (Unicode classes Zl and Zp).
 *   <br/>
 *   Length:  EDAM_USER_NAME_LEN_MIN - EDAM_USER_NAME_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_USER_NAME_REGEX
 *   </dd>
 *
 * <dt>timezone</dt>
 *   <dd>The zone ID for the user's default location.  If present,
 *   this may be used to localize the display of any timestamp for which no
 *   other timezone is available - for example, an note that arrives via
 *   a micro-browser may not contain enough information to display its
 *   local time, so this default timezone may be assigned to the note.
 *   The format must be encoded as a standard zone ID such as
 *   "America/Los_Angeles" or "GMT+08:00"
 *   <br/>
 *   Length:  EDAM_TIMEZONE_LEN_MIN - EDAM_TIMEZONE_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_TIMEZONE_REGEX
 *   </dd>
 *
 * <dt>privilege</dt>
 *   <dd>The level of access permitted for the user.
 *   </dd>
 *
 * <dt>created</dt>
 *   <dd>The date and time when this user account was created in the
 *   service.
 *   </dd>
 *
 * <dt>updated</dt>
 *   <dd>The date and time when this user account was last modified
 *   in the service.
 *   </dd>
 *
 * <dt>deleted</dt>
 *   <dd>If the account has been deleted from the system (e.g. as
 *   the result of a legal request by the user), the date and time of the
 *   deletion will be represented here.  If not, this value will not be set.
 *   </dd>
 *
 * <dt>active</dt>
 *   <dd>If the user account is available for login and
 *   synchronization, this flag will be set to true.
 *   </dd>
 *
 * <dt>shardId</dt>
 *   <dd>The name of the virtual server that manages the state of
 *   this user.  This value is used internally to determine which system should
 *   service requests about this user's data.
 *   </dd>
 *
 * <dt>attributes</dt>
 *   <dd>If present, this will contain a list of the attributes
 *   for this user account.
 *   </dd>
 *
 * <dt>accounting</dt>
 *   <dd>Bookkeeping information for the user's subscription.
 *   </dd>
 * </dl>
 */
struct User {
  1:  required  UserID id,
  2:  optional  string username,
  3:  optional  string email,
  4:  optional  string name,
  6:  optional  string timezone,
  7:  optional  PrivilegeLevel privilege,
  9:  optional  Timestamp created,
  10: optional  Timestamp updated,
  11: optional  Timestamp deleted,
  13: required  bool active,
  14: optional  string shardId,
  15: optional  UserAttributes attributes,
  16: optional  Accounting accounting
}


/**
 * A tag within a user's account is a unique name which may be organized
 * a simple hierarchy.
 *<dl>
 * <dt>guid</dt>
 *   <dd>The unique identifier of this tag. Will be set by the service,
 *   so may be omitted by the client when creating the Tag.
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>name</dt>
 *   <dd>A sequence of characters representing the tag's identifier. 
 *   Case is preserved, but is ignored for comparisons. 
 *   This means that an account may only have one tag with a given name, via
 *   case-insensitive comparison, so an account may not have both "food" and
 *   "Food" tags.
 *   May not contain a comma (','), and may not begin or end with a space.
 *   <br/>
 *   Length:  EDAM_TAG_NAME_LEN_MIN - EDAM_TAG_NAME_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_TAG_NAME_REGEX
 *   </dd>
 *
 * <dt>parentGuid</dt>
 *   <dd>If this is set, then this is the GUID of the tag that
 *   holds this tag within the tag organizational heirarchy.  If this is
 *   not set, then the tag has no parent and it is a "top level" tag.
 *   Cycles are not allowed (e.g. a->parent->parent == a) and will be
 *   rejected by the service.
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>updateSequenceNum</dt>
 *   <dd>A number identifying the last transaction to 
 *   modify the state of this object.  The USN values are sequential within an
 *   account, and can be used to compare the order of modifications within the
 *   service.
 *   </dd>
 * </dl>
 */
struct Tag {
  1:  optional  Guid guid,
  2:  required  string name,
  3:  optional  Guid parentGuid,
  4:  optional  i32 updateSequenceNum
}


/**
 * Structure holding the optional attributes of a Resource
 * <dl>
 * <dt>sourceURL</dt>
 *   <dd>the original location where the resource was hosted
 *   <br/>
 *    Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>timestamp</dt>
 *   <dd>the date and time that is associated with this resource
 *   (e.g. the time embedded in an image from a digital camera with a clock)
 *   </dd>
 *
 * <dt>latitude</dt>
 *   <dd>the latitude where the resource was captured
 *   </dd>
 *
 * <dt>longitude</dt>
 *   <dd>the longitude where the resource was captured
 *   </dd>
 *
 * <dt>altitude</dt>
 *   <dd>the altitude where the resource was captured
 *   </dd>
 *
 * <dt>cameraMake</dt>
 *   <dd>information about an image's camera, e.g. as embedded in
 *   the image's EXIF data
 *   <br/>
 *   Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>cameraModel</dt>
 *   <dd>information about an image's camera, e.g. as embedded
 *   in the image's EXIF data
 *   <br/>
 *   Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>clientWillIndex</dt>
 *   <dd>if true, then the original client that submitted
 *   the resource plans to submit the recognition index for this resource at a
 *   later time. 
 *   </dd>
 *
 * <dt>recoType</dt>
 *   <dd>if the resource has been indexed for searching, this
 *   will contain the value of the 'docType' attribute from the recoIndex.
 *   This may contain one of the following: 'printed', 'speech', 'handwritten',
 *   'picture', or 'unknown'. 
 *   </dd>
 *
 * <dt>fileName</dt>
 *   <dd>if the resource came from a source that provided an
 *   explicit file name, the original name will be stored here.  Many resources
 *   come from unnamed sources, so this will not always be set.
 *   </dd>
 *
 * <dt>attachment</dt>
 *   <dd>this will be true if the resource is a Premium file attachment.  This
 *   will be available within the search grammar so that you can identify
 *   notes that contain attachments.
 *   </dd>
 * </dl>
 */
struct ResourceAttributes {
  1:  optional  string sourceURL,
  2:  optional  Timestamp timestamp,
  3:  optional  double latitude,
  4:  optional  double longitude,
  5:  optional  double altitude,
  6:  optional  string cameraMake,
  7:  optional  string cameraModel,
  8:  optional  bool clientWillIndex,
  9:  optional  string recoType,
  10: optional  string fileName,
  11: optional  bool attachment
}


/**
 * Every media file that is embedded or attached to a note is represented
 * through a Resource entry.
 * <dl>
 * <dt>guid</dt>
 *   <dd>The unique identifier of this resource.  Will be set whenever
 *   a resource is retrieved from the service, but may be null when a client
 *   is creating a resource.
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>noteGuid</dt>
 *   <dd>The unique identifier of the Note that holds this
 *   Resource. Will be set whenever the resource is retrieved from the service,
 *   but may be null when a client is creating a resource.
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>data</dt>
 *   <dd>The contents of the resource.
 *   Maximum length:  The data.body is limited to 25 MB (26214400 bytes)
 *   </dd>
 *
 * <dt>mime</dt>
 *   <dd>The MIME type for the embedded resource.  E.g. "image/gif"
 *   <br/>
 *   Length:  EDAM_MIME_LEN_MIN - EDAM_MIME_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_MIME_REGEX
 *   </dd>
 *
 * <dt>width</dt>
 *   <dd>If set, this contains the display width of this resource, in
 *   pixels.
 *   </dd>
 *
 * <dt>height</dt>
 *   <dd>If set, this contains the display height of this resource,
 *   in pixels.
 *   </dd>
 *
 * <dt>duration</dt>
 *   <dd>If set, this contains the duration of this time-based
 *   clip, in seconds.
 *   </dd>
 *
 * <dt>active</dt>
 *   <dd>DEPRECATED: ignored.
 *   </dd>
 *
 * <dt>recognition</dt>
 *   <dd>If set, this will hold the encoded data that provides
 *   information on search and recognition within this resource.
 *   </dd>
 *
 * <dt>attributes</dt>
 *   <dd>A list of the attributes for this resource.
 *   </dd>
 *
 * <dt>updateSequenceNum</dt>
 *   <dd>A number identifying the last transaction to
 *   modify the state of this object. The USN values are sequential within an
 *   account, and can be used to compare the order of modifications within the
 *   service.
 *   </dd>
 * </dl>
 */
struct Resource {
  1:  optional  Guid guid,
  2:  optional  Guid noteGuid,
  3:  required  Data data,
  4:  optional  string mime,
  5:  optional  i16 width,
  6:  optional  i16 height,
  7:  optional  i16 duration,
  8:  optional  bool active,
  9:  optional  Data recognition,
  11: optional  ResourceAttributes attributes,
  12: optional  i32 updateSequenceNum
}


/**
 * The list of optional attributes that can be stored on a note.
 * <dl>
 * <dt>subjectDate</dt>
 *   <dd>time that the note refers to
 *   </dd>
 *
 * <dt>latitude</dt>
 *   <dd>the latitude where the note was taken
 *   </dd>
 *
 * <dt>longitude</dt>
 *   <dd>the longitude where the note was taken
 *   </dd>
 *
 * <dt>altitude</dt>
 *   <dd>the altitude where the note was taken
 *   </dd>
 *
 * <dt>author</dt>
 *   <dd>the author of the content of the note
 *   <br/>
 *   Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>source</dt>
 *   <dd>the method that the note was added to the account, if the
 *   note wasn't directly authored in an Evernote client.
 *   <br/>
 *   Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>sourceURL</dt>
 *   <dd>the original location where the resource was hosted
 *   <br/>
 *   Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 *
 * <dt>sourceApplication</dt>
 *   <dd>an identifying string for the application that
 *   created this note.  This string does not have a guaranteed syntax or
 *   structure -- it is intended for human inspection and tracking.
 *   <br/>
 *   Length:  EDAM_ATTRIBUTE_LEN_MIN - EDAM_ATTRIBUTE_LEN_MAX
 *   </dd>
 * </dl>
 */
struct NoteAttributes {
  1:  optional  Timestamp subjectDate,
  10: optional  double latitude,
  11: optional  double longitude,
  12: optional  double altitude,
  13: optional  string author,  
  14: optional  string source,
  15: optional  string sourceURL,
  16: optional  string sourceApplication
}


/**
 * Represents a single note in the user's account.
 *
 * <dl>
 * <dt>guid</dt>
 *   <dd>The unique identifier of this note.  Will be set by the
 *   server, but will be omitted by clients calling NoteStore.createNote()
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>title</dt>
 *   <dd>The subject of the note.  Can't begin or end with a space.
 *   <br/>
 *   Length:  EDAM_NOTE_TITLE_LEN_MIN - EDAM_NOTE_TITLE_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_NOTE_TITLE_REGEX
 *   </dd>
 *
 * <dt>content</dt>
 *   <dd>The XHTML block that makes up the note.  This is
 *   the canonical form of the note's contents, so will include abstract
 *   Evernote tags for internal resource references.  A client may create
 *   a separate transformed version of this content for internal presentation,
 *   but the same canonical bytes should be used for transmission and
 *   comparison unless the user chooses to modify their content.
 *   <br/>
 *   Length:  EDAM_NOTE_CONTENT_LEN_MIN - EDAM_NOTE_CONTENT_LEN_MAX
 *   </dd>
 *
 * <dt>contentHash</dt>
 *   <dd>The binary MD5 checksum of the UTF-8 encoded content
 *   body. This will always be set by the server, but clients may choose to omit
 *   this when they submit a note with content. 
 *   <br/>
 *   Length:  EDAM_HASH_LEN (exactly)
 *   </dd>
 *
 * <dt>contentLength</dt>
 *   <dd>The number of Unicode characters in the content of
 *   the note.  This will always be set by the service, but clients may choose
 *   to omit this value when they submit a Note.
 *   </dd>
 *
 * <dt>created</dt>
 *   <dd>The date and time when the note was created in one of the
 *   clients.  In most cases, this will match the user's sense of when
 *   the note was created, and ordering between notes will be based on
 *   ordering of this field.  However, this is not a "reliable" timestamp
 *   if a client has an incorrect clock, so it cannot provide a true absolute
 *   ordering between notes.  Notes created directly through the service
 *   (e.g. via the web GUI) will have an absolutely ordered "created" value.
 *   </dd>
 *
 * <dt>updated</dt>
 *   <dd>The date and time when the note was last modified in one of
 *   the clients.  In most cases, this will match the user's sense of when
 *   the note was modified, but this field may not be absolutely reliable
 *   due to the possibility of client clock errors.
 *   </dd>
 *
 * <dt>deleted</dt>
 *   <dd>If present, the note is considered "deleted", and this
 *   stores the date and time when the note was deleted by one of the clients.
 *   In most cases, this will match the user's sense of when the note was
 *   deleted, but this field may be unreliable due to the possibility of
 *   client clock errors.
 *   </dd>
 * 
 * <dt>active</dt>
 *   <dd>If the note is available for normal actions and viewing,
 *   this flag will be set to true.
 *   </dd>
 *
 * <dt>updateSequenceNum</dt>
 *   <dd>A number identifying the last transaction to
 *   modify the state of this note (including changes to the note's attributes
 *   or resources).  The USN values are sequential within an account,
 *   and can be used to compare the order of modifications within the service.
 *   </dd>
 *
 * <dt>notebookGuid</dt>
 *   <dd>The unique identifier of the notebook that contains
 *   this note.  If no notebookGuid is provided on a call to createNote(), the
 *   default notebook will be used instead.
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>tags</dt>
 *   <dd>A list of the tags that are applied to this note.
 *   If the list of tags are omitted on a call to updateNote(), then
 *   the server will assume that no changes have been made to the resources.
 *   Maximum:  EDAM_NOTE_TAGS_MAX tags per note
 *   </dd>
 *
 * <dt>resources</dt>
 *   <dd>The list of resources that are embedded within this note.
 *   If the list of resources are omitted on a call to updateNote(), then
 *   the server will assume that no changes have been made to the resources.
 *   The binary contents of the resources must be provided when the resource
 *   is first sent to the service, but it will be omitted by the service when
 *   the Note is returned in the future.
 *   Maximum:  EDAM_NOTE_RESOURCES_MAX resources per note
 *   </dd>
 *
 * <dt>attributes</dt>
 *   <dd>A list of the attributes for this note.
 *   If the list of attributes are omitted on a call to updateNote(), then
 *   the server will assume that no changes have been made to the resources.
 *   </dd>
 * </dl>
 */
struct Note {
  1:  optional  Guid guid,
  2:  required  string title,
  3:  optional  string content,
  4:  optional  binary contentHash,
  5:  optional  i32 contentLength,
  6:  required  Timestamp created,
  7:  required  Timestamp updated,
  8:  optional  Timestamp deleted,
  9:  optional  bool active,
  10: optional  i32 updateSequenceNum,
  11: optional  string notebookGuid,
  12: optional  list<Guid> tagGuids,
  13: optional  list<Resource> resources,
  14: optional  NoteAttributes attributes
}


/**
 * If a Notebook has been opened to the public, the Notebook will have a
 * reference to one of these structures, which gives the location and optional
 * description of the externally-visible public Notebook.
 * <dl>
 * <dt>uri</dt>
 *   <dd>If this field is present, then the notebook is published for
 *   mass consumption on the Internet under the provided URI, which is
 *   relative to a defined base publishing URI defined by the service.
 *   This field can only be modified via the web service GUI ... publishing
 *   cannot be modified via an offline client.
 *   <br/>
 *   Length:  EDAM_PUBLISHING_URI_LEN_MIN - EDAM_PUBLISHING_URI_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_PUBLISHING_URI_REGEX
 *   </dd>
 *
 * <dt>order</dt>
 *   <dd>When the notes are publicly displayed, they will be sorted
 *   based on the requested criteria.
 *   </dd>
 *
 * <dt>ascending</dt>
 *   <dd>If this is set to true, then the public notes will be
 *   displayed in ascending order (e.g. from oldest to newest).  Otherwise,
 *   the notes will be displayed in descending order (e.g. newest to oldest).
 *   </dd>
 *
 * <dt>publicDescription</dt>
 *   <dd>This field may be used to provide a short
 *   description of the notebook, which may be displayed when (e.g.) the
 *   notebook is shown in a public view.  Can't begin or end with a space.
 *   <br/>
 *   Length:  EDAM_PUBLISHING_DESCRIPTION_LEN_MIN -
 *            EDAM_PUBLISHING_DESCRIPTION_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_PUBLISHING_DESCRIPTION_REGEX
 *   </dd>
 * </dl>
 */
struct Publishing {
  1:  required  string uri,
  2:  required  NoteSortOrder order,
  3:  required  bool ascending,
  4:  optional  string publicDescription
}


/**
 * A unique container for a set of notes.
 * <dl>
 * <dt>guid</dt>
 *   <dd>The unique identifier of this notebook.
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>name</dt>
 *   <dd>A sequence of characters representing the name of the
 *   notebook.  May be changed by clients, but the account may not contain two
 *   notebooks with names that are equal via a case-insensitive comparison.
 *   Can't begin or end with a space.
 *   <br/>
 *   Length:  EDAM_NOTEBOOK_NAME_LEN_MIN - EDAM_NOTEBOOK_NAME_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_NOTEBOOK_NAME_REGEX
 *   </dd>
 *
 * <dt>updateSequenceNum</dt>
 *   <dd>A number identifying the last transaction to
 *   modify the state of this object.  The USN values are sequential within an
 *   account, and can be used to compare the order of modifications within the
 *   service.
 *   </dd>
 *
 * <dt>defaultNotebook</dt>
 *   <dd>If true, this notebook should be used for new notes
 *   whenever the user has not (or cannot) specify a desired target notebook.
 *   For example, if a note is submitted via SMTP email.
 *   The service will maintain at most one defaultNotebook per account.
 *   If a second notebook is created or updated with defaultNotebook set to
 *   true, the service will automatically update the prior notebook's
 *   defaultNotebook field to false.  If the default notebook is deleted
 *   (i.e. "active" set to false), the "defaultNotebook" field will be
 *   set to false by the service.  If the account has no default notebook
 *   set, the service will use the most recent notebook as the default.
 *   </dd>
 *
 * <dt>serviceCreated</dt>
 *   <dd>The time when this notebook was created on the
 *   service. This will be set on the service during creation, and the service
 *   will provide this value when it returns a Notebook to a client.
 *   The service will ignore this value if it is sent by clients.
 *   </dd>
 *
 * <dt>serviceUpdated</dt>
 *   <dd>The time when this notebook was last modified on the 
 *   service.  This will be set on the service during creation, and the service
 *   will provide this value when it returns a Notebook to a client.
 *   The service will ignore this value if it is sent by clients.
 *   </dd>
 *
 * <dt>publishing</dt>
 *   <dd>If the Notebook has been opened for public access (i.e.
 *   if 'published' is set to true), then this will point to the set of
 *   publishing information for the Notebook (URI, description, etc.).  A
 *   Notebook cannot be published without providing this information, but it
 *   will persist for later use if publishing is ever disabled on the Notebook.
 *   Clients that do not wish to change the publishing behavior of a Notebook
 *   should not set this value when calling NoteStore.updateNotebook().
 *   </dd>
 *
 * <dt>published</dt>
 *   <dd>If this is set to true, then the Notebook will be
 *   accessible to the public via the 'publishing' specification, which must
 *   also be set.  If this is set to false, the Notebook will not be available
 *   to the public. 
 *   Clients that do not wish to change the publishing behavior of a Notebook
 *   should not set this value when calling NoteStore.updateNotebook().
 *   </dd>
 * </dl>
 */
struct Notebook {
  1:  optional  Guid guid,
  2:  required  string name,
  5:  optional  i32 updateSequenceNum,
  6:  optional  bool defaultNotebook,
  7:  optional  Timestamp serviceCreated,
  8:  optional  Timestamp serviceUpdated,
  10: optional  Publishing publishing,
  11: optional  bool published
}


/**
 * A named search associated with the account that can be quickly re-used.
 * <dl>
 * <dt>guid</dt>
 *   <dd>The unique identifier of this search.  Will be set by the
 *   service, so may be omitted by the client when creating.
 *   <br/>
 *   Length:  EDAM_GUID_LEN_MIN - EDAM_GUID_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_GUID_REGEX
 *   </dd>
 *
 * <dt>name</dt>
 *   <dd>The name of the saved search to display in the GUI.  The
 *   account may only contain one search with a given name (case-insensitive
 *   compare). Can't begin or end with a space.
 *   <br/>
 *   Length:  EDAM_SAVED_SEARCH_NAME_LEN_MIN - EDAM_SAVED_SEARCH_NAME_LEN_MAX
 *   <br/>
 *   Regex:  EDAM_SAVED_SEARCH_NAME_REGEX
 *   </dd>
 *
 * <dt>query</dt>
 *   <dd>A string expressing the search to be performed.
 *   <br/>
 *   Length:  EDAM_SAVED_SEARCH_QUERY_LEN_MIN - EDAM_SAVED_SEARCH_QUERY_LEN_MAX
 *   </dd>
 *
 * <dt>format</dt>
 *   <dd>The format of the query string, to determine how to parse 
 *   and process it.
 *   </dd>
 * 
 * <dt>updateSequenceNum</dt>
 *   <dd>A number identifying the last transaction to
 *   modify the state of this object.  The USN values are sequential within an
 *   account, and can be used to compare the order of modifications within the
 *   service.
 *   </dd>
 * </dl>
 */
struct SavedSearch {
  1:  optional  Guid guid,
  2:  required  string name,
  3:  required  string query,
  4:  required  QueryFormat format,
  5:  optional  i32 updateSequenceNum
}
