{**
 * templates/frontend/components/header.tpl
 *
 * Site header: top bar with ISSN, main logo/title/actions,
 * navigation menu, mobile hamburger.
 *}

<header class="zhezu-header" role="banner">

    {* ── Top Bar: ISSN ── *}
    <div class="zhezu-header__top-bar">
        <div class="zhezu-header__top-bar-inner">
            <div class="zhezu-header__issn">
                <span class="zhezu-header__issn-label">{translate key="plugins.themes.zhezujournal.header.issnPrint"}:</span>
                {$currentContext->getData('printIssn')|escape}
                &nbsp;&nbsp;
                <span class="zhezu-header__issn-label">{translate key="plugins.themes.zhezujournal.header.issnOnline"}:</span>
                {$currentContext->getData('onlineIssn')|escape}
            </div>
        </div>
    </div>

    {* ── Main Header: Logo, Title, Actions ── *}
    <div class="zhezu-header__main">

        {* Logo *}
        <div class="zhezu-header__logo">
            <a href="{url page="index"}" aria-label="{translate key="plugins.themes.zhezujournal.header.logoAlt"}">
                {if $currentContext->getLocalizedData('pageHeaderLogoImage')}
                    <img src="{$publicFilesDir}/{$currentContext->getLocalizedData('pageHeaderLogoImage').uploadName|escape}"
                         alt="{$currentContext->getLocalizedData('pageHeaderLogoImage').altText|escape|default:''}"
                         loading="lazy" />
                {/if}
            </a>
        </div>

        {* Journal Title *}
        <div class="zhezu-header__title">
            <a href="{url page="index"}">
                <h1 class="zhezu-header__title-text">
                    {translate key="plugins.themes.zhezujournal.header.journalTitle"}
                </h1>
            </a>
        </div>

        {* Actions: search, language, login *}
        <div class="zhezu-header__actions">

            {* Search Toggle *}
            <div class="zhezu-header__search">
                <button class="zhezu-header__search-toggle"
                        type="button"
                        aria-label="{translate key="plugins.themes.zhezujournal.header.searchToggle"}"
                        data-zhezu-search-toggle>
                    &#128269;
                </button>
                <form class="zhezu-header__search-form"
                      action="{url page="search" op="search"}"
                      method="get"
                      role="search"
                      data-zhezu-search-form>
                    <input class="zhezu-header__search-input"
                           type="search"
                           name="query"
                           placeholder="{translate key="plugins.themes.zhezujournal.header.searchPlaceholder"}"
                           aria-label="{translate key="plugins.themes.zhezujournal.header.searchPlaceholder"}" />
                </form>
            </div>

            {* Language Switcher *}
            <div class="zhezu-header__lang">
                {foreach from=$enabledLocales item=localeName key=localeKey name=localeLoop}
                    <a href="{url page="user" op="setLocale" path=$localeKey}"
                       class="zhezu-header__lang-link{if $currentLocale == $localeKey} zhezu-header__lang-link--active{/if}"
                       aria-label="{$localeName|escape}">
                        {if $localeKey == 'kk'}KZ{elseif $localeKey == 'ru_RU'}RU{elseif $localeKey == 'en_US'}EN{else}{$localeKey|escape}{/if}
                    </a>
                    {if !$smarty.foreach.localeLoop.last}
                        <span class="zhezu-header__lang-sep">|</span>
                    {/if}
                {/foreach}
            </div>

            {* Login / User *}
            <div class="zhezu-header__login">
                {if $isUserLoggedIn}
                    <a href="{url page="submissions"}">
                        <span class="zhezu-header__user-name">{$loggedInUsername|escape}</span>
                    </a>
                {else}
                    <a href="{url page="login"}">
                        {translate key="plugins.themes.zhezujournal.header.login"}
                    </a>
                {/if}
            </div>

            {* Mobile Hamburger *}
            <button class="zhezu-header__hamburger"
                    type="button"
                    aria-label="{translate key="plugins.themes.zhezujournal.header.menuToggle"}"
                    aria-expanded="false"
                    data-zhezu-hamburger>
                <span class="zhezu-header__hamburger-line"></span>
                <span class="zhezu-header__hamburger-line"></span>
                <span class="zhezu-header__hamburger-line"></span>
            </button>

        </div>
    </div>

    {* ── Desktop Navigation ── *}
    <nav class="zhezu-header__nav-wrapper" aria-label="{translate key="plugins.themes.zhezujournal.header.mainNav"}">
        <div class="zhezu-header__nav">
            <ul class="zhezu-header__menu">
                <li class="zhezu-header__menu-item">
                    <a class="zhezu-header__menu-link" href="{url page="index"}">
                        {translate key="plugins.themes.zhezujournal.nav.home"}
                    </a>
                </li>
                <li class="zhezu-header__menu-item">
                    <a class="zhezu-header__menu-link" href="{url page="about"}">
                        {translate key="plugins.themes.zhezujournal.nav.about"}
                    </a>
                </li>
                <li class="zhezu-header__menu-item">
                    <a class="zhezu-header__menu-link" href="{url page="about" op="submissions"}">
                        {translate key="plugins.themes.zhezujournal.nav.forAuthors"}
                    </a>
                </li>
                <li class="zhezu-header__menu-item">
                    <a class="zhezu-header__menu-link" href="{url page="about" op="editorialTeam"}">
                        {translate key="plugins.themes.zhezujournal.nav.peerReview"}
                    </a>
                </li>
                <li class="zhezu-header__menu-item">
                    <a class="zhezu-header__menu-link" href="{url page="issue" op="archive"}">
                        {translate key="plugins.themes.zhezujournal.nav.archive"}
                    </a>
                </li>
                <li class="zhezu-header__menu-item">
                    <a class="zhezu-header__menu-link" href="{url page="about" op="contact"}">
                        {translate key="plugins.themes.zhezujournal.nav.contacts"}
                    </a>
                </li>
            </ul>
        </div>
    </nav>

    {* ── Mobile Navigation ── *}
    <nav class="zhezu-header__mobile-menu"
         aria-label="{translate key="plugins.themes.zhezujournal.header.mobileNav"}"
         data-zhezu-mobile-menu>
        <ul class="zhezu-header__menu">
            <li class="zhezu-header__menu-item">
                <a class="zhezu-header__menu-link" href="{url page="index"}">
                    {translate key="plugins.themes.zhezujournal.nav.home"}
                </a>
            </li>
            <li class="zhezu-header__menu-item">
                <a class="zhezu-header__menu-link" href="{url page="about"}">
                    {translate key="plugins.themes.zhezujournal.nav.about"}
                </a>
            </li>
            <li class="zhezu-header__menu-item">
                <a class="zhezu-header__menu-link" href="{url page="about" op="submissions"}">
                    {translate key="plugins.themes.zhezujournal.nav.forAuthors"}
                </a>
            </li>
            <li class="zhezu-header__menu-item">
                <a class="zhezu-header__menu-link" href="{url page="about" op="editorialTeam"}">
                    {translate key="plugins.themes.zhezujournal.nav.peerReview"}
                </a>
            </li>
            <li class="zhezu-header__menu-item">
                <a class="zhezu-header__menu-link" href="{url page="issue" op="archive"}">
                    {translate key="plugins.themes.zhezujournal.nav.archive"}
                </a>
            </li>
            <li class="zhezu-header__menu-item">
                <a class="zhezu-header__menu-link" href="{url page="about" op="contact"}">
                    {translate key="plugins.themes.zhezujournal.nav.contacts"}
                </a>
            </li>
        </ul>
    </nav>

</header>
