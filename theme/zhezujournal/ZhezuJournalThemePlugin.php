<?php

/**
 * @file ZhezuJournalThemePlugin.php
 *
 * @brief Child theme plugin for Vestnik ZhezU journal.
 *
 * Extends the default OJS theme with custom styles, templates,
 * and theme options for the Zhezkazgan University journal.
 */

declare(strict_types=1);

namespace APP\plugins\themes\zhezujournal;

use PKP\plugins\ThemePlugin;

class ZhezuJournalThemePlugin extends ThemePlugin
{
    /**
     * @copydoc ThemePlugin::isActive()
     */
    public function isActive(): bool
    {
        return true;
    }

    /**
     * Initialize the theme by registering styles, scripts, and options.
     *
     * @return void
     */
    public function init(): void
    {
        // Set parent theme
        $this->setParent('defaultthemeplugin');

        // Register theme options
        $this->addOption('primaryColor', 'colour', [
            'label' => 'plugins.themes.zhezujournal.option.primaryColor',
            'default' => '#1B3A5C',
        ]);

        $this->addOption('secondaryColor', 'colour', [
            'label' => 'plugins.themes.zhezujournal.option.secondaryColor',
            'default' => '#C8A84E',
        ]);

        $this->addOption('baseFont', 'radio', [
            'label' => 'plugins.themes.zhezujournal.option.baseFont',
            'default' => 'roboto',
            'options' => [
                'roboto' => 'Roboto',
                'ptserif' => 'PT Serif',
                'system' => 'plugins.themes.zhezujournal.option.systemFont',
            ],
        ]);

        // Load LESS stylesheets
        $this->addStyle('variables', 'styles/variables.less');
        $this->addStyle('header', 'styles/header.less');
        $this->addStyle('footer', 'styles/footer.less');
        $this->addStyle('homepage', 'styles/homepage.less');
        $this->addStyle('archive', 'styles/archive.less');
        $this->addStyle('article', 'styles/article.less');
        $this->addStyle('editorial-board', 'styles/editorial-board.less');
        $this->addStyle('search', 'styles/search.less');
        $this->addStyle('forms', 'styles/forms.less');
        $this->addStyle('responsive', 'styles/responsive.less');

        // Load Google Fonts
        $this->addStyle(
            'google-fonts',
            'https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&family=PT+Serif:wght@400;700&display=swap',
            ['baseUrl' => '']
        );

        // Load JavaScript
        $this->addScript('zhezujournal', 'assets/js/zhezujournal.js');
    }

    /**
     * Get the display name of this plugin.
     *
     * @return string
     */
    public function getDisplayName(): string
    {
        return __('plugins.themes.zhezujournal.name');
    }

    /**
     * Get the description of this plugin.
     *
     * @return string
     */
    public function getDescription(): string
    {
        return __('plugins.themes.zhezujournal.description');
    }
}
