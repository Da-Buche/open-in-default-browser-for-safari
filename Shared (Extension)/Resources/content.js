function findAnchor(target) {
    if (!(target instanceof Element)) {
        return null;
    }

    return target.closest("a[href]");
}

function isHttpUrl(urlString) {
    try {
        const url = new URL(urlString, window.location.href);
        return url.protocol === "http:" || url.protocol === "https:";
    } catch (_error) {
        return false;
    }
}

document.addEventListener(
    "click",
    (event) => {
        if (event.defaultPrevented || event.button !== 0) {
            return;
        }

        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
            return;
        }

        const anchor = findAnchor(event.target);
        if (!anchor) {
            return;
        }

        const href = anchor.getAttribute("href");
        if (!href || !isHttpUrl(href)) {
            return;
        }

        event.preventDefault();
        event.stopImmediatePropagation();

        const targetUrl = new URL(href, window.location.href).toString();

        browser.runtime.sendMessage({
            type: "openExternal",
            url: targetUrl
        }).then((response) => {
            if (!response || response.ok !== true) {
                // Fallback to normal navigation when the native bridge is unavailable.
                window.location.assign(targetUrl);
            }
        }).catch((error) => {
            console.error("Failed to send openExternal message", error);
            window.location.assign(targetUrl);
        });
    },
    true
);
