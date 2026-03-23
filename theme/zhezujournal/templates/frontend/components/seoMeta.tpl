{**
 * seoMeta.tpl — SEO meta tags for Zhezkazgan University Journal
 *
 * Provides: Open Graph, Twitter Cards, Dublin Core, Schema.org JSON-LD,
 *           Canonical URL, Hreflang tags.
 *
 * Include in header.tpl: {include file="frontend/components/seoMeta.tpl"}
 *}

{* --- Canonical URL --- *}
{if $currentUrl}
<link rel="canonical" href="{$currentUrl|escape}" />
{/if}

{* --- Hreflang for 3 languages (ru, kk, en) --- *}
{if $currentUrl}
{assign var="baseUrl" value=$currentUrl|regex_replace:"/\/(ru_RU|kk|en_US)(\/|$)/":"/$1$2"}
<link rel="alternate" hreflang="ru" href="{$baseUrl|regex_replace:"/\/[a-z]{2}(_[A-Z]{2})?(\/|$)/":"/ru_RU$2"|escape}" />
<link rel="alternate" hreflang="kk" href="{$baseUrl|regex_replace:"/\/[a-z]{2}(_[A-Z]{2})?(\/|$)/":"/kk$2"|escape}" />
<link rel="alternate" hreflang="en" href="{$baseUrl|regex_replace:"/\/[a-z]{2}(_[A-Z]{2})?(\/|$)/":"/en_US$2"|escape}" />
<link rel="alternate" hreflang="x-default" href="{$baseUrl|regex_replace:"/\/[a-z]{2}(_[A-Z]{2})?(\/|$)/":"/ru_RU$2"|escape}" />
{/if}

{* ============================================================= *}
{* Open Graph meta tags                                          *}
{* ============================================================= *}
<meta property="og:site_name" content="{$currentJournal->getLocalizedName()|escape}" />

{if $article}
    {* --- Article page --- *}
    <meta property="og:type" content="article" />
    <meta property="og:title" content="{$article->getLocalizedTitle()|escape}" />
    <meta property="og:description" content="{$article->getLocalizedAbstract()|strip_tags|truncate:200:'...':true|escape}" />
    <meta property="og:url" content="{url page="article" op="view" path=$article->getBestId()}" />
    {if $article->getLocalizedCoverImageUrl()}
        <meta property="og:image" content="{$article->getLocalizedCoverImageUrl()|escape}" />
    {elseif $currentJournal->getLocalizedData('journalThumbnail')}
        <meta property="og:image" content="{$publicFilesDir}/{$currentJournal->getLocalizedData('journalThumbnail').uploadName|escape}" />
    {/if}
    <meta property="article:published_time" content="{$article->getDatePublished()|date_format:'%Y-%m-%dT%H:%M:%S'}" />
    {if $issue}
        <meta property="article:section" content="{$issue->getLocalizedTitle()|escape}" />
    {/if}
    {foreach from=$article->getAuthors() item=author}
        <meta property="article:author" content="{$author->getFullName()|escape}" />
    {/foreach}
{elseif $issue}
    {* --- Issue page --- *}
    <meta property="og:type" content="website" />
    <meta property="og:title" content="{$issue->getLocalizedTitle()|escape}" />
    <meta property="og:description" content="{$currentJournal->getLocalizedDescription()|strip_tags|truncate:200:'...':true|escape}" />
    <meta property="og:url" content="{url page="issue" op="view" path=$issue->getBestId()}" />
{else}
    {* --- General / index page --- *}
    <meta property="og:type" content="website" />
    <meta property="og:title" content="{$currentJournal->getLocalizedName()|escape}" />
    <meta property="og:description" content="{$currentJournal->getLocalizedDescription()|strip_tags|truncate:200:'...':true|escape}" />
    <meta property="og:url" content="{$baseUrl}/{$currentJournal->getPath()|escape}" />
    {if $currentJournal->getLocalizedData('journalThumbnail')}
        <meta property="og:image" content="{$publicFilesDir}/{$currentJournal->getLocalizedData('journalThumbnail').uploadName|escape}" />
    {/if}
{/if}

<meta property="og:locale" content="{$currentLocale|escape}" />
<meta property="og:locale:alternate" content="ru_RU" />
<meta property="og:locale:alternate" content="kk" />
<meta property="og:locale:alternate" content="en_US" />

{* ============================================================= *}
{* Twitter Card meta tags                                        *}
{* ============================================================= *}
<meta name="twitter:card" content="summary_large_image" />
{if $article}
    <meta name="twitter:title" content="{$article->getLocalizedTitle()|escape}" />
    <meta name="twitter:description" content="{$article->getLocalizedAbstract()|strip_tags|truncate:200:'...':true|escape}" />
{else}
    <meta name="twitter:title" content="{$currentJournal->getLocalizedName()|escape}" />
    <meta name="twitter:description" content="{$currentJournal->getLocalizedDescription()|strip_tags|truncate:200:'...':true|escape}" />
{/if}

{* ============================================================= *}
{* Dublin Core metadata                                          *}
{* ============================================================= *}
{if $article}
    <meta name="DC.Title" content="{$article->getLocalizedTitle()|escape}" />
    {foreach from=$article->getAuthors() item=author}
        <meta name="DC.Creator" content="{$author->getFullName()|escape}" />
    {/foreach}
    <meta name="DC.Date" content="{$article->getDatePublished()|date_format:'%Y-%m-%d'}" />
    <meta name="DC.Description" content="{$article->getLocalizedAbstract()|strip_tags|truncate:500:'...':true|escape}" />
    <meta name="DC.Language" content="{$article->getLocale()|escape}" />
    <meta name="DC.Rights" content="{$currentJournal->getLocalizedData('licenseTerms')|strip_tags|escape}" />
    <meta name="DC.Publisher" content="{$currentJournal->getLocalizedName()|escape}" />
    <meta name="DC.Source" content="{$currentJournal->getLocalizedName()|escape}" />
    <meta name="DC.Type" content="Text.Article" />
    <meta name="DC.Format" content="text/html" />
    <meta name="DC.Identifier" content="{url page="article" op="view" path=$article->getBestId()}" />
    {if $article->getStoredPubId('doi')}
        <meta name="DC.Identifier.DOI" content="{$article->getStoredPubId('doi')|escape}" />
    {/if}
    {if $article->getLocalizedSubject()}
        <meta name="DC.Subject" content="{$article->getLocalizedSubject()|escape}" />
    {/if}
{else}
    <meta name="DC.Title" content="{$currentJournal->getLocalizedName()|escape}" />
    <meta name="DC.Publisher" content="{$currentJournal->getLocalizedName()|escape}" />
    <meta name="DC.Language" content="{$currentLocale|escape}" />
{/if}

{* ============================================================= *}
{* Schema.org JSON-LD — ScholarlyArticle                         *}
{* ============================================================= *}
{if $article}
<script type="application/ld+json">
{ldelim}
    "@context": "https://schema.org",
    "@type": "ScholarlyArticle",
    "name": {$article->getLocalizedTitle()|json_encode},
    "headline": {$article->getLocalizedTitle()|json_encode},
    "description": {$article->getLocalizedAbstract()|strip_tags|truncate:500:'...':true|json_encode},
    "url": "{url page="article" op="view" path=$article->getBestId()}",
    "datePublished": "{$article->getDatePublished()|date_format:'%Y-%m-%d'}",
    {if $article->getDateModified()}
    "dateModified": "{$article->getDateModified()|date_format:'%Y-%m-%d'}",
    {/if}
    "inLanguage": "{$article->getLocale()|escape}",
    "author": [
        {foreach from=$article->getAuthors() item=author name=authorLoop}
        {ldelim}
            "@type": "Person",
            "name": {$author->getFullName()|json_encode},
            "givenName": {$author->getLocalizedGivenName()|json_encode},
            "familyName": {$author->getLocalizedFamilyName()|json_encode}
            {if $author->getOrcid()}
            ,"sameAs": "{$author->getOrcid()|escape}"
            {/if}
            {if $author->getLocalizedAffiliation()}
            ,"affiliation": {ldelim}
                "@type": "Organization",
                "name": {$author->getLocalizedAffiliation()|json_encode}
            {rdelim}
            {/if}
        {rdelim}{if !$smarty.foreach.authorLoop.last},{/if}
        {/foreach}
    ],
    "publisher": {ldelim}
        "@type": "Organization",
        "name": {$currentJournal->getLocalizedName()|json_encode}
    {rdelim},
    "isPartOf": {ldelim}
        "@type": "Periodical",
        "name": {$currentJournal->getLocalizedName()|json_encode}
        {if $currentJournal->getData('onlineIssn')}
        ,"issn": "{$currentJournal->getData('onlineIssn')|escape}"
        {elseif $currentJournal->getData('printIssn')}
        ,"issn": "{$currentJournal->getData('printIssn')|escape}"
        {/if}
    {rdelim}
    {if $issue}
    ,"isPartOf": {ldelim}
        "@type": "PublicationIssue",
        "issueNumber": "{$issue->getNumber()|escape}",
        "datePublished": "{$issue->getDatePublished()|date_format:'%Y-%m-%d'}",
        "isPartOf": {ldelim}
            "@type": "PublicationVolume",
            "volumeNumber": "{$issue->getVolume()|escape}"
        {rdelim}
    {rdelim}
    {/if}
    {if $article->getStoredPubId('doi')}
    ,"sameAs": "https://doi.org/{$article->getStoredPubId('doi')|escape}"
    {/if}
    {if $article->getLocalizedSubject()}
    ,"keywords": {$article->getLocalizedSubject()|json_encode}
    {/if}
    {if $article->getPages()}
    ,"pagination": "{$article->getPages()|escape}"
    {/if}
{rdelim}
</script>
{/if}
