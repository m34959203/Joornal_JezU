<?php

/**
 * @file plugins/generic/zhezuCustom/ZhezuCustomPlugin.php
 *
 * Copyright (c) 2026 Zhezkazgan University / Saryarka AI Lab
 * Distributed under the GNU GPL v3. For full terms see the file LICENSE.
 *
 * @class ZhezuCustomPlugin
 *
 * @brief Custom plugin for Vestnik ZhezU journal:
 *        - Injects Yandex.Metrika counter via TemplateManager hook
 *        - Adds article-level view/download statistics block
 *        - Adds "Download full issue" button on issue pages
 */

declare(strict_types=1);

namespace APP\plugins\generic\zhezuCustom;

use APP\core\Application;
use APP\facades\Repo;
use APP\template\TemplateManager;
use PKP\core\JSONMessage;
use PKP\plugins\GenericPlugin;
use PKP\plugins\Hook;

class ZhezuCustomPlugin extends GenericPlugin
{
    // ─── Registration ───────────────────────────────────────────────────

    /**
     * Register the plugin and attach hooks.
     *
     * @param string $category Plugin category
     * @param string $path     Plugin path
     * @param int|null $mainContextId Main context ID
     *
     * @return bool Whether registration succeeded
     */
    public function register($category, $path, $mainContextId = null): bool
    {
        $success = parent::register($category, $path, $mainContextId);

        if ($success && $this->getEnabled()) {
            // Hook: inject custom header code (Yandex.Metrika)
            Hook::add(
                'TemplateManager::display',
                [$this, 'callbackInjectHeaderCode']
            );

            // Hook: add article statistics block on article landing page
            Hook::add(
                'Templates::Article::Main',
                [$this, 'callbackArticleStats']
            );

            // Hook: add "Download full issue" button on issue TOC
            Hook::add(
                'Templates::Issue::Issue::Article',
                [$this, 'callbackDownloadIssueButton']
            );
        }

        return $success;
    }

    // ─── Plugin metadata ────────────────────────────────────────────────

    /**
     * Get the display name of this plugin.
     *
     * @return string Translated display name
     */
    public function getDisplayName(): string
    {
        return __('plugins.generic.zhezuCustom.displayName');
    }

    /**
     * Get a description of this plugin.
     *
     * @return string Translated description
     */
    public function getDescription(): string
    {
        return __('plugins.generic.zhezuCustom.description');
    }

    /**
     * Determine whether this plugin can be disabled.
     *
     * @return bool
     */
    public function getCanDisable(): bool
    {
        return true;
    }

    /**
     * Determine whether this plugin can be enabled.
     *
     * @return bool
     */
    public function getCanEnable(): bool
    {
        return true;
    }

    // ─── Settings ───────────────────────────────────────────────────────

    /**
     * Get plugin setting names used in the settings form.
     *
     * @return array<string> List of setting keys
     */
    public function getSettingNames(): array
    {
        return [
            'yandexMetrikaId',
            'showArticleStats',
            'showDownloadIssue',
        ];
    }

    /**
     * Get plugin actions for the management interface.
     *
     * @param \PKP\core\PKPRequest $request
     * @param array $actionArgs
     *
     * @return array Actions to display in plugin management
     */
    public function getActions($request, $actionArgs): array
    {
        $actions = parent::getActions($request, $actionArgs);

        if (!$this->getEnabled()) {
            return $actions;
        }

        $router = $request->getRouter();

        $linkAction = new \PKP\linkAction\LinkAction(
            'settings',
            new \PKP\linkAction\request\AjaxModal(
                $router->url(
                    $request,
                    null,
                    null,
                    'manage',
                    null,
                    [
                        'verb' => 'settings',
                        'plugin' => $this->getName(),
                        'category' => 'generic',
                    ]
                ),
                $this->getDisplayName()
            ),
            __('manager.plugins.settings'),
            null
        );

        array_unshift($actions, $linkAction);

        return $actions;
    }

    /**
     * Handle management actions (settings form).
     *
     * @param array $args   Action arguments
     * @param \PKP\core\PKPRequest $request
     *
     * @return JSONMessage JSON response
     */
    public function manage($args, $request): JSONMessage
    {
        switch ($request->getUserVar('verb')) {
            case 'settings':
                $templateMgr = TemplateManager::getManager($request);
                $templateMgr->assign([
                    'pluginName' => $this->getName(),
                    'yandexMetrikaId' => $this->getSetting(
                        $request->getContext()?->getId() ?? \PKP\core\PKPApplication::SITE_CONTEXT_ID,
                        'yandexMetrikaId'
                    ),
                    'showArticleStats' => $this->getSetting(
                        $request->getContext()?->getId() ?? \PKP\core\PKPApplication::SITE_CONTEXT_ID,
                        'showArticleStats'
                    ) ?? true,
                    'showDownloadIssue' => $this->getSetting(
                        $request->getContext()?->getId() ?? \PKP\core\PKPApplication::SITE_CONTEXT_ID,
                        'showDownloadIssue'
                    ) ?? true,
                ]);

                return new JSONMessage(
                    true,
                    $templateMgr->fetch($this->getTemplateResource('settingsForm.tpl'))
                );

            case 'save':
                $contextId = $request->getContext()?->getId()
                    ?? \PKP\core\PKPApplication::SITE_CONTEXT_ID;

                $this->updateSetting(
                    $contextId,
                    'yandexMetrikaId',
                    trim((string) $request->getUserVar('yandexMetrikaId'))
                );
                $this->updateSetting(
                    $contextId,
                    'showArticleStats',
                    (bool) $request->getUserVar('showArticleStats')
                );
                $this->updateSetting(
                    $contextId,
                    'showDownloadIssue',
                    (bool) $request->getUserVar('showDownloadIssue')
                );

                return new JSONMessage(true);
        }

        return parent::manage($args, $request);
    }

    // ─── Hook: Yandex.Metrika injection ─────────────────────────────────

    /**
     * Inject Yandex.Metrika counter code into the page header.
     *
     * @param string $hookName  Hook name
     * @param array  $args      [TemplateManager, template, sendContentType, charset, output]
     *
     * @return bool false to allow other hooks to process
     */
    public function callbackInjectHeaderCode(string $hookName, array $args): bool
    {
        $templateMgr = $args[0];
        $template = $args[1] ?? '';

        // Only inject on frontend templates (not backend/admin)
        if (str_starts_with($template, 'management/') || str_starts_with($template, 'admin/')) {
            return false;
        }

        $request = Application::get()->getRequest();
        $contextId = $request->getContext()?->getId()
            ?? \PKP\core\PKPApplication::SITE_CONTEXT_ID;

        $metrikaId = $this->getSetting($contextId, 'yandexMetrikaId');

        if (empty($metrikaId)) {
            return false;
        }

        $metrikaId = (int) $metrikaId;

        $metrikaCode = <<<HTML
<!-- Yandex.Metrika counter — ZhezU Custom Plugin -->
<script type="text/javascript">
    (function(m,e,t,r,i,k,a){m[i]=m[i]||function(){(m[i].a=m[i].a||[]).push(arguments)};
    m[i].l=1*new Date();
    for(var j=0;j<document.scripts.length;j++){if(document.scripts[j].src===r)return;}
    k=e.createElement(t),a=e.getElementsByTagName(t)[0],k.async=1,k.src=r,a.parentNode.insertBefore(k,a)})
    (window, document, "script", "https://mc.yandex.ru/metrika/tag.js", "ym");
    ym({$metrikaId}, "init", {
        clickmap:true,
        trackLinks:true,
        accurateTrackBounce:true,
        webvisor:true
    });
</script>
<noscript><div><img src="https://mc.yandex.ru/watch/{$metrikaId}" style="position:absolute; left:-9999px;" alt="" /></div></noscript>
<!-- /Yandex.Metrika counter -->
HTML;

        $templateMgr->addHeader('zhezuMetrika', $metrikaCode);

        return false;
    }

    // ─── Hook: Article statistics block ─────────────────────────────────

    /**
     * Add article view/download statistics block on the article landing page.
     *
     * @param string $hookName  Hook name
     * @param array  $args      [output, templateMgr, ...]
     *
     * @return bool false to allow other hooks to process
     */
    public function callbackArticleStats(string $hookName, array $args): bool
    {
        $output =& $args[2];
        $templateMgr = $args[1];

        $request = Application::get()->getRequest();
        $contextId = $request->getContext()?->getId()
            ?? \PKP\core\PKPApplication::SITE_CONTEXT_ID;

        $showStats = $this->getSetting($contextId, 'showArticleStats');
        if ($showStats === false) {
            return false;
        }

        $article = $templateMgr->getTemplateVars('article');
        $publication = $templateMgr->getTemplateVars('currentPublication')
            ?? $templateMgr->getTemplateVars('publication');

        if (!$article || !$publication) {
            return false;
        }

        $submissionId = $article->getId();

        // Retrieve statistics via the StatsService
        $views = 0;
        $downloads = 0;

        try {
            $statsService = app()->get('publicationStats');

            // Abstract views
            $metricsAbstract = $statsService->getTotals([
                'submissionIds' => [$submissionId],
                'assocTypes' => [Application::ASSOC_TYPE_SUBMISSION],
            ]);
            $views = $metricsAbstract[0]['metric'] ?? 0;

            // Galley downloads
            $metricsGalley = $statsService->getTotals([
                'submissionIds' => [$submissionId],
                'assocTypes' => [Application::ASSOC_TYPE_SUBMISSION_FILE],
            ]);
            $downloads = $metricsGalley[0]['metric'] ?? 0;
        } catch (\Throwable $e) {
            // Statistics service may not be available, fail silently
            error_log('ZhezuCustomPlugin: Could not retrieve stats — ' . $e->getMessage());
        }

        $templateMgr->assign([
            'zhezuArticleViews' => (int) $views,
            'zhezuArticleDownloads' => (int) $downloads,
        ]);

        $output .= $templateMgr->fetch($this->getTemplateResource('articleStats.tpl'));

        return false;
    }

    // ─── Hook: Download full issue button ───────────────────────────────

    /**
     * Add a "Download full issue" button on the issue table of contents page.
     *
     * Injects the button once per issue page (tracks via template variable).
     *
     * @param string $hookName  Hook name
     * @param array  $args      [output, templateMgr, ...]
     *
     * @return bool false to allow other hooks to process
     */
    public function callbackDownloadIssueButton(string $hookName, array $args): bool
    {
        $output =& $args[2];
        $templateMgr = $args[1];

        $request = Application::get()->getRequest();
        $contextId = $request->getContext()?->getId()
            ?? \PKP\core\PKPApplication::SITE_CONTEXT_ID;

        $showButton = $this->getSetting($contextId, 'showDownloadIssue');
        if ($showButton === false) {
            return false;
        }

        // Only inject once per page render
        if ($templateMgr->getTemplateVars('zhezuIssueButtonInjected')) {
            return false;
        }

        $issue = $templateMgr->getTemplateVars('issue');
        if (!$issue) {
            return false;
        }

        $issueGalleys = $issue->getGalleys();
        if (empty($issueGalleys)) {
            return false;
        }

        $templateMgr->assign([
            'zhezuIssueGalleys' => $issueGalleys,
            'zhezuIssueButtonInjected' => true,
        ]);

        $output .= $templateMgr->fetch($this->getTemplateResource('downloadIssueButton.tpl'));

        return false;
    }

    // ─── Template resource path ─────────────────────────────────────────

    /**
     * Get the path to a template resource within this plugin.
     *
     * @param string $name Template filename
     *
     * @return string Full plugin template path
     */
    public function getTemplateResource($name = null): string
    {
        return parent::getTemplateResource($name);
    }
}
