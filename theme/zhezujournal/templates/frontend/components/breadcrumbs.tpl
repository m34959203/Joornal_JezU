{**
 * templates/frontend/components/breadcrumbs.tpl
 *
 * Breadcrumb navigation component.
 *}

<nav class="zhezu-breadcrumbs" aria-label="{translate key="plugins.themes.zhezujournal.breadcrumbs.label"}">
    <ol class="zhezu-breadcrumbs__list">
        <li class="zhezu-breadcrumbs__item">
            <a class="zhezu-breadcrumbs__link" href="{url page="index"}">
                {translate key="plugins.themes.zhezujournal.nav.home"}
            </a>
        </li>

        {if $currentTitle}
            <li class="zhezu-breadcrumbs__separator" aria-hidden="true">/</li>
            <li class="zhezu-breadcrumbs__item zhezu-breadcrumbs__item--current"
                aria-current="page">
                {$currentTitle|escape}
            </li>
        {/if}

        {if $issue}
            <li class="zhezu-breadcrumbs__separator" aria-hidden="true">/</li>
            <li class="zhezu-breadcrumbs__item">
                <a class="zhezu-breadcrumbs__link" href="{url page="issue" op="archive"}">
                    {translate key="plugins.themes.zhezujournal.nav.archive"}
                </a>
            </li>
            <li class="zhezu-breadcrumbs__separator" aria-hidden="true">/</li>
            <li class="zhezu-breadcrumbs__item zhezu-breadcrumbs__item--current"
                aria-current="page">
                {$issue->getLocalizedTitle()|escape}
            </li>
        {/if}

        {if $article}
            <li class="zhezu-breadcrumbs__separator" aria-hidden="true">/</li>
            <li class="zhezu-breadcrumbs__item zhezu-breadcrumbs__item--current"
                aria-current="page">
                {$article->getLocalizedTitle()|escape|truncate:60:"..."}
            </li>
        {/if}
    </ol>
</nav>
