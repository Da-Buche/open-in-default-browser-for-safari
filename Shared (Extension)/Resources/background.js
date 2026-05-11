const NATIVE_APP_ID = "com.dabuche.open-in-default-browser.Extension";

browser.runtime.onMessage.addListener((request) => {
    if (!request || request.type !== "openExternal" || typeof request.url !== "string") {
        return undefined;
    }

    return browser.runtime.sendNativeMessage(NATIVE_APP_ID, {
        command: "openExternal",
        url: request.url
    }).then((response) => {
        if (response && typeof response.ok === "boolean") {
            return response;
        }

        return { ok: false, error: "Invalid native response" };
    }).catch((error) => {
        console.error("Failed to open URL in default browser", error);
        return { ok: false, error: String(error) };
    });
});
