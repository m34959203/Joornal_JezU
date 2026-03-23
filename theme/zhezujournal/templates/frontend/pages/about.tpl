{**
 * templates/frontend/pages/about.tpl
 *
 * About the journal page: main content area (70%) with
 * sidebar navigation (30%) linking to policy sub-pages.
 *}

{include file="frontend/components/header.tpl"}

{include file="frontend/components/breadcrumbs.tpl" currentTitle={translate key="plugins.themes.zhezujournal.about.pageTitle"}}

<main class="zhezu-about" role="main">

    <h1 class="zhezu-about__title">
        {translate key="plugins.themes.zhezujournal.about.pageTitle"}
    </h1>

    <div class="zhezu-about__layout">

        {* ── Main Content (70%) ── *}
        <div class="zhezu-about__content">

            {* About the Journal — from OJS settings *}
            {if $currentContext->getLocalizedData('about')}
                <section class="zhezu-about__section" id="about-description">
                    <div class="zhezu-about__text">
                        {$currentContext->getLocalizedData('about')|strip_unsafe_html}
                    </div>
                </section>
            {/if}

            {* Focus and Scope *}
            {if $currentContext->getLocalizedData('focusScopeDesc')}
                <section class="zhezu-about__section" id="about-focus">
                    <h2 class="zhezu-about__section-title">
                        {translate key="plugins.themes.zhezujournal.about.focusScope"}
                    </h2>
                    <div class="zhezu-about__text">
                        {$currentContext->getLocalizedData('focusScopeDesc')|strip_unsafe_html}
                    </div>
                </section>
            {/if}

            {* Editorial Policy *}
            {if $currentContext->getLocalizedData('editorialPolicy')}
                <section class="zhezu-about__section" id="about-editorial-policy">
                    <h2 class="zhezu-about__section-title">
                        {translate key="plugins.themes.zhezujournal.about.editorialPolicy"}
                    </h2>
                    <div class="zhezu-about__text">
                        {$currentContext->getLocalizedData('editorialPolicy')|strip_unsafe_html}
                    </div>
                </section>
            {/if}

            {* Peer Review Process *}
            {if $currentContext->getLocalizedData('reviewPolicy')}
                <section class="zhezu-about__section" id="about-review-policy">
                    <h2 class="zhezu-about__section-title">
                        {translate key="plugins.themes.zhezujournal.about.reviewPolicy"}
                    </h2>
                    <div class="zhezu-about__text">
                        {$currentContext->getLocalizedData('reviewPolicy')|strip_unsafe_html}
                    </div>
                </section>
            {/if}

            {* Publication Ethics *}
            {if $currentContext->getLocalizedData('openAccessPolicy')}
                <section class="zhezu-about__section" id="about-open-access">
                    <h2 class="zhezu-about__section-title">
                        {translate key="plugins.themes.zhezujournal.about.openAccess"}
                    </h2>
                    <div class="zhezu-about__text">
                        {$currentContext->getLocalizedData('openAccessPolicy')|strip_unsafe_html}
                    </div>
                </section>
            {/if}

            {* Archiving *}
            {if $currentContext->getLocalizedData('lockssLicense') || $currentContext->getLocalizedData('clockssLicense')}
                <section class="zhezu-about__section" id="about-archiving">
                    <h2 class="zhezu-about__section-title">
                        {translate key="plugins.themes.zhezujournal.about.archiving"}
                    </h2>
                    <div class="zhezu-about__text">
                        {if $currentContext->getLocalizedData('lockssLicense')}
                            {$currentContext->getLocalizedData('lockssLicense')|strip_unsafe_html}
                        {/if}
                        {if $currentContext->getLocalizedData('clockssLicense')}
                            {$currentContext->getLocalizedData('clockssLicense')|strip_unsafe_html}
                        {/if}
                    </div>
                </section>
            {/if}

            {* Sponsorship *}
            {if $currentContext->getLocalizedData('sponsorship')}
                <section class="zhezu-about__section" id="about-sponsorship">
                    <h2 class="zhezu-about__section-title">
                        {translate key="plugins.themes.zhezujournal.about.sponsorship"}
                    </h2>
                    <div class="zhezu-about__text">
                        {$currentContext->getLocalizedData('sponsorship')|strip_unsafe_html}
                    </div>
                </section>
            {/if}
        </div>

        {* ── Sidebar (30%) ── *}
        <aside class="zhezu-about__sidebar" role="complementary">
            <nav class="zhezu-about__sidebar-nav"
                 aria-label="{translate key="plugins.themes.zhezujournal.about.sidebarNav"}">
                <ul class="zhezu-about__sidebar-list">
                    <li class="zhezu-about__sidebar-item">
                        <a class="zhezu-about__sidebar-link" href="#about-focus">
                            {translate key="plugins.themes.zhezujournal.about.focusScope"}
                        </a>
                    </li>
                    <li class="zhezu-about__sidebar-item">
                        <a class="zhezu-about__sidebar-link" href="#about-editorial-policy">
                            {translate key="plugins.themes.zhezujournal.about.editorialPolicy"}
                        </a>
                    </li>
                    <li class="zhezu-about__sidebar-item">
                        <a class="zhezu-about__sidebar-link"
                           href="{url page="about" op="editorialTeam"}">
                            {translate key="plugins.themes.zhezujournal.about.editorialBoard"}
                        </a>
                    </li>
                    <li class="zhezu-about__sidebar-item">
                        <a class="zhezu-about__sidebar-link" href="#about-review-policy">
                            {translate key="plugins.themes.zhezujournal.about.reviewPolicy"}
                        </a>
                    </li>
                    <li class="zhezu-about__sidebar-item">
                        <a class="zhezu-about__sidebar-link" href="#about-open-access">
                            {translate key="plugins.themes.zhezujournal.about.openAccess"}
                        </a>
                    </li>
                    <li class="zhezu-about__sidebar-item">
                        <a class="zhezu-about__sidebar-link"
                           href="{url page="about" op="submissions"}">
                            {translate key="plugins.themes.zhezujournal.about.authorGuidelines"}
                        </a>
                    </li>
                    <li class="zhezu-about__sidebar-item">
                        <a class="zhezu-about__sidebar-link"
                           href="{url page="about" op="contact"}">
                            {translate key="plugins.themes.zhezujournal.nav.contacts"}
                        </a>
                    </li>
                </ul>
            </nav>
        </aside>

    </div>

</main>

{include file="frontend/components/footer.tpl"}
