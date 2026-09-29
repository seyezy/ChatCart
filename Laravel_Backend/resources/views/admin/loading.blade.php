<div class="cc-page-loader" id="cc-page-loader" hidden role="status" aria-live="polite" aria-label="Loading page">
    <span class="visually-hidden">Loading page…</span>
    <div aria-hidden="true">
        <div class="cc-skeleton cc-loader-title"></div>
        <div class="cc-skeleton cc-loader-subtitle"></div>
        <div class="cc-loader-grid">
            @for($i = 0; $i < 4; $i++)
                <div class="cc-loader-card"><div class="cc-skeleton"></div><div class="cc-skeleton"></div></div>
            @endfor
        </div>
        <div class="cc-skeleton cc-loader-panel"></div>
    </div>
</div>
