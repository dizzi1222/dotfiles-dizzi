<script lang="ts">
  import { lang } from '$lib/stores/lang.svelte';
  import { i18n, type Lang } from '$lib/i18n';

  let currentLang = $state<Lang>('es');
  lang.subscribe(v => currentLang = v);

  const t = (path: string) => {
    let v: any = i18n[currentLang];
    for (const k of path.split('.')) { if (v) v = v[k]; else return ''; }
    return v || '';
  };
</script>

<footer class="footer">
  <div class="footer__left">
    <span class="footer__mode">NORMAL</span>
    <span>index.html</span>
  </div>
  <div class="footer__right">
    <span>utf-8</span>
    <span>html</span>
    <span>1,1</span>
    <span>All</span>
    <span>
      <a href="https://dizzi1222.github.io/dhardi.dev" target="_blank" style="color:var(--accent-tertiary);text-decoration:underline;display:inline-flex;align-items:center;gap:4px">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:middle">
          <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 13c-2.32 0-4.45-1.09-5.83-2.93l2.5-4.33A5.003 5.003 0 0012 17c.74 0 1.44-.16 2.07-.45L17.5 18.5 14 20.9c-1.67.7-3.5.7-5.17 0L12 18zm5.09-3.07l-2.5-4.33A5.003 5.003 0 0012 7c-.74 0-1.44.16-2.07.45L7.5 5.5 11 3.1c1.67-.7 3.5-.7 5.17 0L14 6.93l3.09 5.34v2.66z"/>
        </svg>
        {t('footer.commercial')}
      </a>
    </span>
  </div>
</footer>
