// Finicky 4 is the default browser and routes every clicked link.
// Managed by chezmoi: edit ~/.chezmoi/home/dot_finicky.js, then `chezmoi apply`.
// Docs: https://github.com/johnste/finicky/wiki

// Workspace page links only; notion.com (marketing/help) and notion.site
// (public pages) stay in the browser.
const notionWorkspaceHosts = ["app.notion.com", "www.notion.so", "notion.so"];

export default {
  defaultBrowser: "Google Chrome",
  rewrite: [
    {
      // Hand Notion links to the app directly as notion://. Opening the https
      // link in Chrome first (Notion's "Open links in desktop app" setting)
      // leaves a redirect tab behind on every click.
      match: (url) => url.protocol === "https:" && notionWorkspaceHosts.includes(url.host),
      url: (url) => new URL(`notion://${url.host}${url.pathname}${url.search}${url.hash}`),
    },
  ],
  handlers: [
    {
      match: (url) => url.protocol === "notion:",
      browser: "Notion",
    },
  ],
};
