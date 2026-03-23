{**
 * templates/frontend/components/footer.tpl
 *
 * Site footer: branding, founder, address, navigation,
 * founded year, analytics counter.
 *}

<footer class="zhezu-footer" role="contentinfo">
    <div class="zhezu-footer__inner">

        {* ── Branding Column ── *}
        <div class="zhezu-footer__branding">
            <div class="zhezu-footer__logo">
                {if $currentContext->getLocalizedData('pageHeaderLogoImage')}
                    <img src="{$publicFilesDir}/{$currentContext->getLocalizedData('pageHeaderLogoImage').uploadName|escape}"
                         alt="{translate key="plugins.themes.zhezujournal.footer.logoAlt"}"
                         loading="lazy" />
                {/if}
            </div>

            <h2 class="zhezu-footer__title">
                {translate key="plugins.themes.zhezujournal.footer.journalTitle"}
            </h2>

            <p class="zhezu-footer__founder">
                {translate key="plugins.themes.zhezujournal.footer.founder"}
            </p>

            <address class="zhezu-footer__address">
                {translate key="plugins.themes.zhezujournal.footer.address"}
            </address>

            <p class="zhezu-footer__founded">
                {translate key="plugins.themes.zhezujournal.footer.foundedYear"}
            </p>
        </div>

        {* ── Navigation Column ── *}
        <div class="zhezu-footer__nav">
            <h3 class="zhezu-footer__nav-title">
                {translate key="plugins.themes.zhezujournal.footer.navTitle"}
            </h3>
            <ul class="zhezu-footer__nav-list">
                <li>
                    <a class="zhezu-footer__nav-link" href="{url page="index"}">
                        {translate key="plugins.themes.zhezujournal.nav.home"}
                    </a>
                </li>
                <li>
                    <a class="zhezu-footer__nav-link" href="{url page="about"}">
                        {translate key="plugins.themes.zhezujournal.nav.about"}
                    </a>
                </li>
                <li>
                    <a class="zhezu-footer__nav-link" href="{url page="about" op="submissions"}">
                        {translate key="plugins.themes.zhezujournal.nav.forAuthors"}
                    </a>
                </li>
                <li>
                    <a class="zhezu-footer__nav-link" href="{url page="issue" op="archive"}">
                        {translate key="plugins.themes.zhezujournal.nav.archive"}
                    </a>
                </li>
                <li>
                    <a class="zhezu-footer__nav-link" href="{url page="about" op="contact"}">
                        {translate key="plugins.themes.zhezujournal.nav.contacts"}
                    </a>
                </li>
            </ul>
        </div>

        {* ── Contact Column ── *}
        <div class="zhezu-footer__contact">
            <h3 class="zhezu-footer__contact-title">
                {translate key="plugins.themes.zhezujournal.footer.contactTitle"}
            </h3>
            <div class="zhezu-footer__contact-item">
                {translate key="plugins.themes.zhezujournal.footer.email"}:
                <a href="mailto:{$currentContext->getData('contactEmail')|escape}">
                    {$currentContext->getData('contactEmail')|escape}
                </a>
            </div>
            <div class="zhezu-footer__contact-item">
                {translate key="plugins.themes.zhezujournal.footer.phone"}:
                {$currentContext->getData('contactPhone')|escape}
            </div>
        </div>

    </div>

    {* ── Bottom Bar ── *}
    <div class="zhezu-footer__bottom">
        <p class="zhezu-footer__copyright">
            &copy; {$smarty.now|date_format:"%Y"} {translate key="plugins.themes.zhezujournal.footer.copyright"}
        </p>
        <div class="zhezu-footer__metrics">
            {* Yandex.Metrika counter placeholder — insert counter code via OJS sidebar or custom block *}
        </div>
    </div>

</footer>
