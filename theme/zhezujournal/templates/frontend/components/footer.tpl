{**
 * templates/frontend/components/footer.tpl
 *
 * Site footer: branding, founder, address, navigation,
 * contact, social links, founded year, analytics counter.
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
                    <a class="zhezu-footer__nav-link zhezu-footer__nav-link--home" href="{url page="index"}">
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
            <div class="zhezu-footer__contact-item">
                {translate key="plugins.themes.zhezujournal.footer.whatsapp"}:
                <a href="https://wa.me/77474218803" target="_blank" rel="noopener">
                    +7 (747) 421-88-03
                </a>
            </div>

            {* ── Social Links ── *}
            <div class="zhezu-footer__social">
                <h4 class="zhezu-footer__social-title">
                    {translate key="plugins.themes.zhezujournal.footer.social"}
                </h4>
                <div class="zhezu-footer__social-links">
                    <a href="https://facebook.com/ZhezUniver" target="_blank" rel="noopener" aria-label="Facebook" class="zhezu-footer__social-link">
                        Facebook
                    </a>
                    <a href="https://instagram.com/zhez_university" target="_blank" rel="noopener" aria-label="Instagram" class="zhezu-footer__social-link">
                        Instagram
                    </a>
                </div>
            </div>
        </div>

    </div>

    {* ── Bottom Bar ── *}
    <div class="zhezu-footer__bottom">
        <p class="zhezu-footer__copyright">
            &copy; {$smarty.now|date_format:"%Y"} {translate key="plugins.themes.zhezujournal.footer.copyright"}
        </p>
        <div class="zhezu-footer__metrics">
            {* Yandex.Metrika counter — replace XXXXXXXX with actual counter ID *}
            <!-- Yandex.Metrika counter -->
            <script type="text/javascript">
                (function(m,e,t,r,i,k,a){ldelim}m[i]=m[i]||function(){ldelim}(m[i].a=m[i].a||[]).push(arguments){rdelim};
                m[i].l=1*new Date();
                for (var j = 0; j < document.scripts.length; j++) {ldelim}if (document.scripts[j].src === r) {ldelim} return; {rdelim}{rdelim}
                k=e.createElement(t),a=e.getElementsByTagName(t)[0],k.async=1,k.src=r,a.parentNode.insertBefore(k,a){rdelim})
                (window, document, "script", "https://mc.yandex.ru/metrika/tag.js", "ym");

                ym(XXXXXXXX, "init", {ldelim}
                    clickmap:true,
                    trackLinks:true,
                    accurateTrackBounce:true,
                    webvisor:true
                {rdelim});
            </script>
            <noscript><div><img src="https://mc.yandex.ru/watch/XXXXXXXX" style="position:absolute; left:-9999px;" alt="" /></div></noscript>
            <!-- /Yandex.Metrika counter -->
        </div>
    </div>

</footer>
