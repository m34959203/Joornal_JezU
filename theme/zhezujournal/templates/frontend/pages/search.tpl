{**
 * templates/frontend/pages/search.tpl
 *
 * Search results page: search form, advanced filters,
 * results list with pagination, empty state.
 *}

{include file="frontend/components/header.tpl"}

{include file="frontend/components/breadcrumbs.tpl" currentTitle={translate key="plugins.themes.zhezujournal.search.pageTitle"}}

<main class="zhezu-search" role="main">

    <h1 class="zhezu-search__title">
        {translate key="plugins.themes.zhezujournal.search.pageTitle"}
    </h1>

    {* ── Main Search Form ── *}
    <form class="zhezu-search__form"
          action="{url page="search" op="search"}"
          method="get" role="search">
        <input class="zhezu-search__input"
               type="search"
               name="query"
               value="{$searchQuery|escape}"
               placeholder="{translate key="plugins.themes.zhezujournal.search.placeholder"}"
               aria-label="{translate key="plugins.themes.zhezujournal.search.placeholder"}" />
        <button class="zhezu-search__submit" type="submit">
            {translate key="plugins.themes.zhezujournal.search.submit"}
        </button>
    </form>

    {* ── Advanced Search Toggle ── *}
    <div class="zhezu-search__advanced">
        <button class="zhezu-search__advanced-toggle" type="button"
                data-zhezu-toggle="zhezu-search__advanced-form"
                aria-expanded="false">
            {translate key="plugins.themes.zhezujournal.search.advancedToggle"}
        </button>

        <form class="zhezu-search__advanced-form" id="zhezu-search__advanced-form"
              action="{url page="search" op="search"}"
              method="get" hidden>

            <div class="zhezu-search__advanced-fields">
                {* Author *}
                <div class="zhezu-form__group">
                    <label class="zhezu-form__label" for="searchAuthors">
                        {translate key="plugins.themes.zhezujournal.search.author"}
                    </label>
                    <input class="zhezu-form__input" type="text"
                           id="searchAuthors" name="authors"
                           value="{$searchAuthors|escape}" />
                </div>

                {* Keywords *}
                <div class="zhezu-form__group">
                    <label class="zhezu-form__label" for="searchKeywords">
                        {translate key="plugins.themes.zhezujournal.search.keywords"}
                    </label>
                    <input class="zhezu-form__input" type="text"
                           id="searchKeywords" name="subject"
                           value="{$searchSubject|escape}" />
                </div>

                {* DOI *}
                <div class="zhezu-form__group">
                    <label class="zhezu-form__label" for="searchDoi">
                        DOI
                    </label>
                    <input class="zhezu-form__input" type="text"
                           id="searchDoi" name="doi"
                           value="{$searchDoi|escape}"
                           placeholder="10.xxxxx/xxxxx" />
                </div>

                {* Date Range *}
                <div class="zhezu-search__advanced-dates">
                    <div class="zhezu-form__group">
                        <label class="zhezu-form__label" for="searchDateFrom">
                            {translate key="plugins.themes.zhezujournal.search.dateFrom"}
                        </label>
                        <input class="zhezu-form__input" type="date"
                               id="searchDateFrom" name="dateFromYear"
                               value="{$searchDateFrom|escape}" />
                    </div>
                    <div class="zhezu-form__group">
                        <label class="zhezu-form__label" for="searchDateTo">
                            {translate key="plugins.themes.zhezujournal.search.dateTo"}
                        </label>
                        <input class="zhezu-form__input" type="date"
                               id="searchDateTo" name="dateToYear"
                               value="{$searchDateTo|escape}" />
                    </div>
                </div>
            </div>

            <div class="zhezu-form__actions">
                <button class="zhezu-search__submit" type="submit">
                    {translate key="plugins.themes.zhezujournal.search.submit"}
                </button>
            </div>
        </form>
    </div>

    {* ── Results ── *}
    {if $searchQuery || $searchAuthors || $searchSubject || $searchDoi}

        {* Results Summary *}
        {if $results->getCount()}
            <p class="zhezu-search__summary">
                {translate key="plugins.themes.zhezujournal.search.resultsCount"
                    count=$results->getCount()}
                {if $searchQuery}
                    {translate key="plugins.themes.zhezujournal.search.resultsFor"}
                    <span class="zhezu-search__query-text">"{$searchQuery|escape}"</span>
                {/if}
            </p>
        {/if}

        {* Results List *}
        {if $results->getCount()}
            <ul class="zhezu-search__results">
                {iterate from=results item=result}
                    {assign var=submission value=$result.publishedSubmission}
                    {assign var=pub value=$submission->getCurrentPublication()}
                    <li class="zhezu-search__result-item">
                        {* Title *}
                        <h2 class="zhezu-search__result-title">
                            <a href="{url page="article" op="view" path=$submission->getBestId()}">
                                {$submission->getLocalizedTitle()|escape}
                            </a>
                        </h2>

                        {* Authors *}
                        {if $submission->getAuthorString()}
                            <p class="zhezu-search__result-authors">
                                {$submission->getAuthorString()|escape}
                            </p>
                        {/if}

                        {* Publication meta: journal, vol, issue, pages *}
                        <p class="zhezu-search__result-meta">
                            {if $result.issue}
                                {$result.issue->getLocalizedTitle()|escape}
                            {/if}
                            {if $pub->getData('pages')}
                                &mdash; {translate key="plugins.themes.zhezujournal.issue.pages"}:
                                {$pub->getData('pages')|escape}
                            {/if}
                        </p>

                        {* Abstract excerpt *}
                        {if $pub->getLocalizedData('abstract')}
                            <p class="zhezu-search__result-excerpt">
                                {$pub->getLocalizedData('abstract')|strip_unsafe_html|truncate:250:"..."}
                            </p>
                        {/if}

                        {* DOI *}
                        {if $pub->getData('pub-id::doi')}
                            <p class="zhezu-search__result-doi">
                                DOI:
                                <a href="https://doi.org/{$pub->getData('pub-id::doi')|escape}"
                                   target="_blank" rel="noopener">
                                    {$pub->getData('pub-id::doi')|escape}
                                </a>
                            </p>
                        {/if}
                    </li>
                {/iterate}
            </ul>

            {* Pagination *}
            {if $results->getPageCount() > 1}
                <nav class="zhezu-search__pagination"
                     aria-label="{translate key="plugins.themes.zhezujournal.search.pagination"}">

                    {* Previous *}
                    {if $results->getPage() > 1}
                        <a class="zhezu-search__page-link"
                           href="{url page="search" op="search" params=$prevPageParams}"
                           aria-label="{translate key="plugins.themes.zhezujournal.search.prevPage"}">
                            &laquo;
                        </a>
                    {else}
                        <span class="zhezu-search__page-link zhezu-search__page-link--disabled">&laquo;</span>
                    {/if}

                    {* Page Numbers *}
                    {section name=pageNum loop=$results->getPageCount() start=0}
                        {assign var=pageNumber value=$smarty.section.pageNum.index+1}
                        {if $pageNumber == $results->getPage()}
                            <span class="zhezu-search__page-link zhezu-search__page-link--active"
                                  aria-current="page">
                                {$pageNumber}
                            </span>
                        {else}
                            <a class="zhezu-search__page-link"
                               href="{url page="search" op="search" params=$pageParams[$pageNumber]}">
                                {$pageNumber}
                            </a>
                        {/if}
                    {/section}

                    {* Next *}
                    {if $results->getPage() < $results->getPageCount()}
                        <a class="zhezu-search__page-link"
                           href="{url page="search" op="search" params=$nextPageParams}"
                           aria-label="{translate key="plugins.themes.zhezujournal.search.nextPage"}">
                            &raquo;
                        </a>
                    {else}
                        <span class="zhezu-search__page-link zhezu-search__page-link--disabled">&raquo;</span>
                    {/if}

                </nav>
            {/if}

        {else}
            {* No Results *}
            <div class="zhezu-search__no-results">
                <div class="zhezu-search__no-results-icon">&#128270;</div>
                <p class="zhezu-search__no-results-text">
                    {translate key="plugins.themes.zhezujournal.search.noResults"}
                </p>
                <p class="zhezu-search__no-results-hint">
                    {translate key="plugins.themes.zhezujournal.search.noResultsHint"}
                </p>
            </div>
        {/if}

    {/if}

</main>

{include file="frontend/components/footer.tpl"}
