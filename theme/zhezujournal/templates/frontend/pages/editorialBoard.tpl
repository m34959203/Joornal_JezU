{**
 * templates/frontend/pages/editorialBoard.tpl
 *
 * Editorial board page: sections for chief editor,
 * secretary, and members with 3-column table layout
 * and Scopus/WoS/ORCID profile buttons.
 *}

{include file="frontend/components/header.tpl"}

{include file="frontend/components/breadcrumbs.tpl" currentTitle={translate key="plugins.themes.zhezujournal.editorial.pageTitle"}}

<main class="zhezu-editorial" role="main">
    <h1 class="zhezu-editorial__title">
        {translate key="plugins.themes.zhezujournal.editorial.pageTitle"}
    </h1>

    {* ── Chief Editor ── *}
    <section class="zhezu-editorial__section">
        <h2 class="zhezu-editorial__section-title">
            {translate key="plugins.themes.zhezujournal.editorial.chiefEditor"}
        </h2>

        {* Desktop Table *}
        <table class="zhezu-editorial__table">
            <thead>
                <tr>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--name">
                        {translate key="plugins.themes.zhezujournal.editorial.colName"}
                    </th>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--info">
                        {translate key="plugins.themes.zhezujournal.editorial.colInfo"}
                    </th>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--profiles">
                        {translate key="plugins.themes.zhezujournal.editorial.colProfiles"}
                    </th>
                </tr>
            </thead>
            <tbody>
                {if $chiefEditors}
                    {foreach from=$chiefEditors item=editor}
                        <tr>
                            <td class="zhezu-editorial__cell">
                                <span class="zhezu-editorial__name">{$editor.name|escape}</span>
                            </td>
                            <td class="zhezu-editorial__cell">
                                <span class="zhezu-editorial__degree">{$editor.degree|escape}</span><br/>
                                <span class="zhezu-editorial__organization">{$editor.organization|escape}</span>
                                {if $editor.country}
                                    <div class="zhezu-editorial__country">{$editor.country|escape}</div>
                                {/if}
                            </td>
                            <td class="zhezu-editorial__cell zhezu-editorial__profiles">
                                {if $editor.scopus}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--scopus"
                                       href="{$editor.scopus|escape}" target="_blank" rel="noopener">
                                        Scopus
                                    </a>
                                {/if}
                                {if $editor.wos}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--wos"
                                       href="{$editor.wos|escape}" target="_blank" rel="noopener">
                                        WoS
                                    </a>
                                {/if}
                                {if $editor.orcid}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--orcid"
                                       href="{$editor.orcid|escape}" target="_blank" rel="noopener">
                                        ORCID
                                    </a>
                                {/if}
                            </td>
                        </tr>
                    {/foreach}
                {/if}
            </tbody>
        </table>

        {* Mobile Cards *}
        {if $chiefEditors}
            {foreach from=$chiefEditors item=editor}
                <div class="zhezu-editorial__card">
                    <h3 class="zhezu-editorial__card-name">{$editor.name|escape}</h3>
                    <div class="zhezu-editorial__card-info">
                        {$editor.degree|escape}<br/>
                        {$editor.organization|escape}
                        {if $editor.country}
                            <br/>{$editor.country|escape}
                        {/if}
                    </div>
                    <div class="zhezu-editorial__card-profiles">
                        {if $editor.scopus}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--scopus"
                               href="{$editor.scopus|escape}" target="_blank" rel="noopener">Scopus</a>
                        {/if}
                        {if $editor.wos}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--wos"
                               href="{$editor.wos|escape}" target="_blank" rel="noopener">WoS</a>
                        {/if}
                        {if $editor.orcid}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--orcid"
                               href="{$editor.orcid|escape}" target="_blank" rel="noopener">ORCID</a>
                        {/if}
                    </div>
                </div>
            {/foreach}
        {/if}
    </section>

    {* ── Executive Secretary ── *}
    <section class="zhezu-editorial__section">
        <h2 class="zhezu-editorial__section-title">
            {translate key="plugins.themes.zhezujournal.editorial.secretary"}
        </h2>

        <table class="zhezu-editorial__table">
            <thead>
                <tr>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--name">
                        {translate key="plugins.themes.zhezujournal.editorial.colName"}
                    </th>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--info">
                        {translate key="plugins.themes.zhezujournal.editorial.colInfo"}
                    </th>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--profiles">
                        {translate key="plugins.themes.zhezujournal.editorial.colProfiles"}
                    </th>
                </tr>
            </thead>
            <tbody>
                {if $secretaries}
                    {foreach from=$secretaries item=editor}
                        <tr>
                            <td class="zhezu-editorial__cell">
                                <span class="zhezu-editorial__name">{$editor.name|escape}</span>
                            </td>
                            <td class="zhezu-editorial__cell">
                                <span class="zhezu-editorial__degree">{$editor.degree|escape}</span><br/>
                                <span class="zhezu-editorial__organization">{$editor.organization|escape}</span>
                                {if $editor.country}
                                    <div class="zhezu-editorial__country">{$editor.country|escape}</div>
                                {/if}
                            </td>
                            <td class="zhezu-editorial__cell zhezu-editorial__profiles">
                                {if $editor.scopus}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--scopus"
                                       href="{$editor.scopus|escape}" target="_blank" rel="noopener">Scopus</a>
                                {/if}
                                {if $editor.wos}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--wos"
                                       href="{$editor.wos|escape}" target="_blank" rel="noopener">WoS</a>
                                {/if}
                                {if $editor.orcid}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--orcid"
                                       href="{$editor.orcid|escape}" target="_blank" rel="noopener">ORCID</a>
                                {/if}
                            </td>
                        </tr>
                    {/foreach}
                {/if}
            </tbody>
        </table>

        {* Mobile Cards *}
        {if $secretaries}
            {foreach from=$secretaries item=editor}
                <div class="zhezu-editorial__card">
                    <h3 class="zhezu-editorial__card-name">{$editor.name|escape}</h3>
                    <div class="zhezu-editorial__card-info">
                        {$editor.degree|escape}<br/>
                        {$editor.organization|escape}
                        {if $editor.country}<br/>{$editor.country|escape}{/if}
                    </div>
                    <div class="zhezu-editorial__card-profiles">
                        {if $editor.scopus}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--scopus"
                               href="{$editor.scopus|escape}" target="_blank" rel="noopener">Scopus</a>
                        {/if}
                        {if $editor.wos}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--wos"
                               href="{$editor.wos|escape}" target="_blank" rel="noopener">WoS</a>
                        {/if}
                        {if $editor.orcid}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--orcid"
                               href="{$editor.orcid|escape}" target="_blank" rel="noopener">ORCID</a>
                        {/if}
                    </div>
                </div>
            {/foreach}
        {/if}
    </section>

    {* ── Editorial Board Members ── *}
    <section class="zhezu-editorial__section">
        <h2 class="zhezu-editorial__section-title">
            {translate key="plugins.themes.zhezujournal.editorial.members"}
        </h2>

        <table class="zhezu-editorial__table">
            <thead>
                <tr>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--name">
                        {translate key="plugins.themes.zhezujournal.editorial.colName"}
                    </th>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--info">
                        {translate key="plugins.themes.zhezujournal.editorial.colInfo"}
                    </th>
                    <th class="zhezu-editorial__table-header zhezu-editorial__table-header--profiles">
                        {translate key="plugins.themes.zhezujournal.editorial.colProfiles"}
                    </th>
                </tr>
            </thead>
            <tbody>
                {if $boardMembers}
                    {foreach from=$boardMembers item=editor}
                        <tr>
                            <td class="zhezu-editorial__cell">
                                <span class="zhezu-editorial__name">{$editor.name|escape}</span>
                            </td>
                            <td class="zhezu-editorial__cell">
                                <span class="zhezu-editorial__degree">{$editor.degree|escape}</span><br/>
                                <span class="zhezu-editorial__organization">{$editor.organization|escape}</span>
                                {if $editor.country}
                                    <div class="zhezu-editorial__country">{$editor.country|escape}</div>
                                {/if}
                            </td>
                            <td class="zhezu-editorial__cell zhezu-editorial__profiles">
                                {if $editor.scopus}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--scopus"
                                       href="{$editor.scopus|escape}" target="_blank" rel="noopener">Scopus</a>
                                {/if}
                                {if $editor.wos}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--wos"
                                       href="{$editor.wos|escape}" target="_blank" rel="noopener">WoS</a>
                                {/if}
                                {if $editor.orcid}
                                    <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--orcid"
                                       href="{$editor.orcid|escape}" target="_blank" rel="noopener">ORCID</a>
                                {/if}
                            </td>
                        </tr>
                    {/foreach}
                {/if}
            </tbody>
        </table>

        {* Mobile Cards *}
        {if $boardMembers}
            {foreach from=$boardMembers item=editor}
                <div class="zhezu-editorial__card">
                    <h3 class="zhezu-editorial__card-name">{$editor.name|escape}</h3>
                    <div class="zhezu-editorial__card-info">
                        {$editor.degree|escape}<br/>
                        {$editor.organization|escape}
                        {if $editor.country}<br/>{$editor.country|escape}{/if}
                    </div>
                    <div class="zhezu-editorial__card-profiles">
                        {if $editor.scopus}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--scopus"
                               href="{$editor.scopus|escape}" target="_blank" rel="noopener">Scopus</a>
                        {/if}
                        {if $editor.wos}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--wos"
                               href="{$editor.wos|escape}" target="_blank" rel="noopener">WoS</a>
                        {/if}
                        {if $editor.orcid}
                            <a class="zhezu-editorial__profile-btn zhezu-editorial__profile-btn--orcid"
                               href="{$editor.orcid|escape}" target="_blank" rel="noopener">ORCID</a>
                        {/if}
                    </div>
                </div>
            {/foreach}
        {/if}
    </section>

</main>

{include file="frontend/components/footer.tpl"}
