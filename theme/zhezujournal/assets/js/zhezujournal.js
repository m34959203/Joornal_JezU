/**
 * zhezujournal.js
 *
 * Main JavaScript for ZhezuJournal theme.
 * Features: mobile hamburger menu, search field expand/collapse,
 * smooth scroll for anchor links.
 */

'use strict';

(function () {
    /**
     * Wait for DOM to be ready before initializing.
     */
    document.addEventListener('DOMContentLoaded', function () {
        initHamburgerMenu();
        initSearchToggle();
        initSmoothScroll();
    });

    // ── Hamburger Menu ──────────────────────────────────────────────────────

    /**
     * Toggle mobile navigation menu on hamburger button click.
     * Updates aria-expanded attribute for accessibility.
     */
    function initHamburgerMenu() {
        var hamburger = document.querySelector('[data-zhezu-hamburger]');
        var mobileMenu = document.querySelector('[data-zhezu-mobile-menu]');

        if (!hamburger || !mobileMenu) {
            return;
        }

        hamburger.addEventListener('click', function () {
            var isOpen = hamburger.classList.toggle('zhezu-header__hamburger--open');
            mobileMenu.classList.toggle('zhezu-header__mobile-menu--open');
            hamburger.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
        });

        // Close mobile menu when clicking outside
        document.addEventListener('click', function (event) {
            if (!hamburger.contains(event.target) && !mobileMenu.contains(event.target)) {
                hamburger.classList.remove('zhezu-header__hamburger--open');
                mobileMenu.classList.remove('zhezu-header__mobile-menu--open');
                hamburger.setAttribute('aria-expanded', 'false');
            }
        });

        // Close mobile menu on Escape key
        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                hamburger.classList.remove('zhezu-header__hamburger--open');
                mobileMenu.classList.remove('zhezu-header__mobile-menu--open');
                hamburger.setAttribute('aria-expanded', 'false');
            }
        });
    }

    // ── Search Toggle ───────────────────────────────────────────────────────

    /**
     * Expand/collapse the header search field on toggle button click.
     * Focuses the input when expanded.
     */
    function initSearchToggle() {
        var toggleBtn = document.querySelector('[data-zhezu-search-toggle]');
        var searchForm = document.querySelector('[data-zhezu-search-form]');

        if (!toggleBtn || !searchForm) {
            return;
        }

        var searchInput = searchForm.querySelector('.zhezu-header__search-input');

        toggleBtn.addEventListener('click', function (event) {
            event.stopPropagation();
            var isExpanded = searchForm.classList.toggle('zhezu-header__search-form--expanded');

            if (isExpanded && searchInput) {
                searchInput.focus();
            }
        });

        // Collapse search when clicking outside
        document.addEventListener('click', function (event) {
            if (!searchForm.contains(event.target) && !toggleBtn.contains(event.target)) {
                searchForm.classList.remove('zhezu-header__search-form--expanded');
            }
        });

        // Collapse on Escape key
        if (searchInput) {
            searchInput.addEventListener('keydown', function (event) {
                if (event.key === 'Escape') {
                    searchForm.classList.remove('zhezu-header__search-form--expanded');
                    toggleBtn.focus();
                }
            });
        }
    }

    // ── Smooth Scroll ───────────────────────────────────────────────────────

    /**
     * Enable smooth scrolling for anchor links that point to
     * elements on the same page. Accounts for sticky header height.
     */
    function initSmoothScroll() {
        var anchorLinks = document.querySelectorAll('a[href^="#"]');

        if (!anchorLinks.length) {
            return;
        }

        anchorLinks.forEach(function (link) {
            link.addEventListener('click', function (event) {
                var targetId = this.getAttribute('href');

                if (!targetId || targetId === '#') {
                    return;
                }

                var targetElement = document.querySelector(targetId);

                if (!targetElement) {
                    return;
                }

                event.preventDefault();

                var header = document.querySelector('.zhezu-header');
                var headerHeight = header ? header.offsetHeight : 0;
                var targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - headerHeight - 16;

                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });

                // Update URL hash without jumping
                if (history.pushState) {
                    history.pushState(null, null, targetId);
                }
            });
        });
    }

})();
