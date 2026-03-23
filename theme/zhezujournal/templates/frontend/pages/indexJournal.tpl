{**
 * templates/frontend/pages/indexJournal.tpl
 *
 * Journal homepage: hero with CTA buttons, current issue,
 * article list, announcements.
 *}

{include file="frontend/components/header.tpl"}

<main class="zhezu-home" role="main">

    {* ── Hero Section ── *}
    <section class="zhezu-home__hero">
        <h2 class="zhezu-home__hero-title">
            {translate key="plugins.themes.zhezujournal.home.heroTitle"}
        </h2>
        <p class="zhezu-home__hero-subtitle">
            {translate key="plugins.themes.zhezujournal.home.heroSubtitle"}
        </p>
        <div class="zhezu-home__cta-group">
            <a class="zhezu-home__cta zhezu-home__cta--primary"
               href="{url page="about" op="submissions"}">
                {translate key="plugins.themes.zhezujournal.home.ctaSubmit"}
            </a>
            <a class="zhezu-home__cta zhezu-home__cta--secondary"
               href="{url page="issue" op="current"}">
                {translate key="plugins.themes.zhezujournal.home.ctaCurrent"}
            </a>
        </div>
    </section>

    {* ── Current Issue ── *}
    {if $issue}
        <section class="zhezu-home__current-issue">
            <h2 class="zhezu-home__section-title">
                {translate key="plugins.themes.zhezujournal.home.currentIssue"}
            </h2>

            <div class="zhezu-home__issue">
                {* Cover Image *}
                {if $issue->getLocalizedCoverImageUrl()}
                    <div class="zhezu-home__issue-cover">
                        <a href="{url page="issue" op="view" path=$issue->getBestIssueId()}">
                            <img src="{$issue->getLocalizedCoverImageUrl()|escape}"
                                 alt="{$issue->getLocalizedCoverImageAltText()|escape|default:''}"
                                 loading="lazy" />
                        </a>
                    </div>
                {/if}

                {* Issue Info & Articles *}
                <div class="zhezu-home__issue-info">
                    <h3 class="zhezu-home__issue-title">
                        <a href="{url page="issue" op="view" path=$issue->getBestIssueId()}">
                            {$issue->getLocalizedTitle()|escape}
                        </a>
                    </h3>

                    {if $issue->getDatePublished()}
                        <p class="zhezu-home__issue-meta">
                            {translate key="plugins.themes.zhezujournal.home.published"}:
                            {$issue->getDatePublished()|date_format:$dateFormatShort}
                        </p>
                    {/if}

                    {* Article List *}
                    {if $publishedSubmissions && $publishedSubmissions|@count}
                        <ul class="zhezu-home__articles">
                            {foreach from=$publishedSubmissions item=article}
                                <li class="zhezu-home__article-item">
                                    <h4 class="zhezu-home__article-title">
                                        <a href="{url page="article" op="view" path=$article->getBestId()}">
                                            {$article->getLocalizedTitle()|escape}
                                        </a>
                                    </h4>
                                    {if $article->getAuthorString()}
                                        <p class="zhezu-home__article-authors">
                                            {$article->getAuthorString()|escape}
                                        </p>
                                    {/if}
                                </li>
                            {/foreach}
                        </ul>
                    {/if}
                </div>
            </div>
        </section>
    {/if}

    {* ── Announcements ── *}
    {if $numAnnouncementsHomepage && $announcements|@count}
        <section class="zhezu-home__announcements">
            <h2 class="zhezu-home__section-title">
                {translate key="plugins.themes.zhezujournal.home.announcements"}
            </h2>
            {foreach from=$announcements item=announcement}
                <article class="zhezu-home__announcement-item">
                    <h3 class="zhezu-home__announcement-title">
                        <a href="{url page="announcement" op="view" path=$announcement->getId()}">
                            {$announcement->getLocalizedTitle()|escape}
                        </a>
                    </h3>
                    <p class="zhezu-home__announcement-date">
                        {$announcement->getDatePosted()|date_format:$dateFormatShort}
                    </p>
                    <p class="zhezu-home__announcement-summary">
                        {$announcement->getLocalizedDescriptionShort()|strip_unsafe_html}
                    </p>
                </article>
            {/foreach}
        </section>
    {/if}

</main>

{include file="frontend/components/footer.tpl"}
