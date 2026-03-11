# Web Development Research Questions

## 1. GET vs POST

**Critical Differences:**

- **GET**: Data is sent in the URL (visible in address bar and browser history). Limited data size (~2000 characters).

- **POST**: Data is sent in the request body (not visible in URL). No size limit. More secure for sensitive data.

**For register.html:** Use **POST**

- **Why**: Registration forms contain sensitive data (passwords, personal info) that should NOT appear in URLs or browser history. POST keeps this data hidden and secure.

---

## 2. Semantic HTML

**Why use `<header>`, `<nav>`, `<main>`, `<footer>`, `section` instead of just `<div>`?**

- **Accessibility**: Screen readers can navigate better (e.g., "jump to main content")
- **SEO**: Search engines understand page structure and prioritize content better
- **Maintainability**: Code is easier to read and understand for developers
- **Understandable**: Tags describe their content/purpose, not just formatting

---

## 3. The Request/Response Cycle

**When you type google.com and hit Enter:**

1. **DNS Lookup**: Browser asks DNS server "What's the IP address for google.com?"
2. **DNS Response**: DNS returns the IP address (e.g., 142.250.80.46)
3. **HTTP Request**: Browser sends request to that IP address
4. **Server Response**: Google's server sends back HTML, CSS, JavaScript
5. **Rendering**: Browser displays the page
