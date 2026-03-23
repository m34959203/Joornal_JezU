{**
 * templates/frontend/pages/contact.tpl
 *
 * Contact page: editorial office address, phone, email,
 * map placeholder, and feedback form.
 *}

{include file="frontend/components/header.tpl"}

{include file="frontend/components/breadcrumbs.tpl" currentTitle={translate key="plugins.themes.zhezujournal.contact.pageTitle"}}

<main class="zhezu-contact" role="main">

    <h1 class="zhezu-contact__title">
        {translate key="plugins.themes.zhezujournal.contact.pageTitle"}
    </h1>

    <div class="zhezu-contact__layout">

        {* ── Contact Information ── *}
        <div class="zhezu-contact__info">

            {* Editorial Office *}
            <section class="zhezu-contact__section">
                <h2 class="zhezu-contact__section-title">
                    {translate key="plugins.themes.zhezujournal.contact.editorialOffice"}
                </h2>

                {* Mailing Address *}
                {if $currentContext->getLocalizedData('mailingAddress')}
                    <div class="zhezu-contact__item">
                        <span class="zhezu-contact__item-icon">&#128205;</span>
                        <div class="zhezu-contact__item-content">
                            <span class="zhezu-contact__item-label">
                                {translate key="plugins.themes.zhezujournal.contact.address"}
                            </span>
                            <address class="zhezu-contact__address">
                                {$currentContext->getLocalizedData('mailingAddress')|escape|nl2br}
                            </address>
                        </div>
                    </div>
                {/if}

                {* Contact Name *}
                {if $currentContext->getData('contactName')}
                    <div class="zhezu-contact__item">
                        <span class="zhezu-contact__item-icon">&#128100;</span>
                        <div class="zhezu-contact__item-content">
                            <span class="zhezu-contact__item-label">
                                {translate key="plugins.themes.zhezujournal.contact.person"}
                            </span>
                            <span>{$currentContext->getData('contactName')|escape}</span>
                        </div>
                    </div>
                {/if}

                {* Phone *}
                {if $currentContext->getData('contactPhone')}
                    <div class="zhezu-contact__item">
                        <span class="zhezu-contact__item-icon">&#128222;</span>
                        <div class="zhezu-contact__item-content">
                            <span class="zhezu-contact__item-label">
                                {translate key="plugins.themes.zhezujournal.contact.phone"}
                            </span>
                            <a href="tel:{$currentContext->getData('contactPhone')|escape}">
                                {$currentContext->getData('contactPhone')|escape}
                            </a>
                        </div>
                    </div>
                {/if}

                {* Email *}
                {if $currentContext->getData('contactEmail')}
                    <div class="zhezu-contact__item">
                        <span class="zhezu-contact__item-icon">&#9993;</span>
                        <div class="zhezu-contact__item-content">
                            <span class="zhezu-contact__item-label">
                                {translate key="plugins.themes.zhezujournal.contact.email"}
                            </span>
                            <a href="mailto:{$currentContext->getData('contactEmail')|escape}">
                                {$currentContext->getData('contactEmail')|escape}
                            </a>
                        </div>
                    </div>
                {/if}
            </section>

            {* Support Contact *}
            {if $currentContext->getData('supportName')}
                <section class="zhezu-contact__section">
                    <h2 class="zhezu-contact__section-title">
                        {translate key="plugins.themes.zhezujournal.contact.techSupport"}
                    </h2>

                    <div class="zhezu-contact__item">
                        <span class="zhezu-contact__item-icon">&#128100;</span>
                        <div class="zhezu-contact__item-content">
                            <span>{$currentContext->getData('supportName')|escape}</span>
                        </div>
                    </div>

                    {if $currentContext->getData('supportPhone')}
                        <div class="zhezu-contact__item">
                            <span class="zhezu-contact__item-icon">&#128222;</span>
                            <div class="zhezu-contact__item-content">
                                <a href="tel:{$currentContext->getData('supportPhone')|escape}">
                                    {$currentContext->getData('supportPhone')|escape}
                                </a>
                            </div>
                        </div>
                    {/if}

                    {if $currentContext->getData('supportEmail')}
                        <div class="zhezu-contact__item">
                            <span class="zhezu-contact__item-icon">&#9993;</span>
                            <div class="zhezu-contact__item-content">
                                <a href="mailto:{$currentContext->getData('supportEmail')|escape}">
                                    {$currentContext->getData('supportEmail')|escape}
                                </a>
                            </div>
                        </div>
                    {/if}
                </section>
            {/if}

            {* Map *}
            <section class="zhezu-contact__map">
                <h2 class="zhezu-contact__section-title">
                    {translate key="plugins.themes.zhezujournal.contact.map"}
                </h2>
                <div class="zhezu-contact__map-embed">
                    {* Replace src with actual 2GIS / Google Maps embed URL *}
                    <iframe
                        src="https://2gis.kz/jezkazgan/firm/0/center/67.7122,47.7833/zoom/16"
                        width="100%"
                        height="400"
                        style="border:0; border-radius: 8px;"
                        loading="lazy"
                        allowfullscreen
                        referrerpolicy="no-referrer-when-downgrade"
                        title="{translate key="plugins.themes.zhezujournal.contact.mapTitle"}">
                    </iframe>
                </div>
            </section>
        </div>

        {* ── Feedback Form ── *}
        <div class="zhezu-contact__form-wrapper">
            <section class="zhezu-contact__form-section">
                <h2 class="zhezu-contact__section-title">
                    {translate key="plugins.themes.zhezujournal.contact.feedbackTitle"}
                </h2>

                {if $contactFormSuccessMessage}
                    <div class="zhezu-contact__success" role="alert">
                        {translate key="plugins.themes.zhezujournal.contact.feedbackSuccess"}
                    </div>
                {/if}

                <form class="zhezu-contact__form"
                      action="{url page="about" op="contact"}"
                      method="post">

                    {csrf}

                    {* Name *}
                    <div class="zhezu-form__group">
                        <label class="zhezu-form__label zhezu-form__label--required"
                               for="contactName">
                            {translate key="plugins.themes.zhezujournal.contact.formName"}
                        </label>
                        <input class="zhezu-form__input{if $errors.name} zhezu-form__input--error{/if}"
                               type="text" id="contactName" name="name"
                               value="{$contactName|escape}"
                               required
                               aria-required="true" />
                        {if $errors.name}
                            <span class="zhezu-form__error">{$errors.name|escape}</span>
                        {/if}
                    </div>

                    {* Email *}
                    <div class="zhezu-form__group">
                        <label class="zhezu-form__label zhezu-form__label--required"
                               for="contactEmail">
                            {translate key="plugins.themes.zhezujournal.contact.formEmail"}
                        </label>
                        <input class="zhezu-form__input{if $errors.email} zhezu-form__input--error{/if}"
                               type="email" id="contactEmail" name="email"
                               value="{$contactEmail|escape}"
                               required
                               aria-required="true" />
                        {if $errors.email}
                            <span class="zhezu-form__error">{$errors.email|escape}</span>
                        {/if}
                    </div>

                    {* Subject *}
                    <div class="zhezu-form__group">
                        <label class="zhezu-form__label zhezu-form__label--required"
                               for="contactSubject">
                            {translate key="plugins.themes.zhezujournal.contact.formSubject"}
                        </label>
                        <input class="zhezu-form__input{if $errors.subject} zhezu-form__input--error{/if}"
                               type="text" id="contactSubject" name="subject"
                               value="{$contactSubject|escape}"
                               required
                               aria-required="true" />
                        {if $errors.subject}
                            <span class="zhezu-form__error">{$errors.subject|escape}</span>
                        {/if}
                    </div>

                    {* Message *}
                    <div class="zhezu-form__group">
                        <label class="zhezu-form__label zhezu-form__label--required"
                               for="contactMessage">
                            {translate key="plugins.themes.zhezujournal.contact.formMessage"}
                        </label>
                        <textarea class="zhezu-form__textarea{if $errors.body} zhezu-form__textarea--error{/if}"
                                  id="contactMessage" name="body"
                                  rows="6" required
                                  aria-required="true">{$contactBody|escape}</textarea>
                        {if $errors.body}
                            <span class="zhezu-form__error">{$errors.body|escape}</span>
                        {/if}
                    </div>

                    {* Submit *}
                    <div class="zhezu-form__actions">
                        <button class="zhezu-form__submit" type="submit">
                            {translate key="plugins.themes.zhezujournal.contact.formSubmit"}
                        </button>
                    </div>
                </form>
            </section>
        </div>

    </div>

</main>

{include file="frontend/components/footer.tpl"}
