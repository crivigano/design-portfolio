(function () {
    var nav = document.querySelector(".site-nav");
    var toggle = nav && nav.querySelector(".nav-toggle");
    if (!toggle) return;

    function setOpen(open) {
        nav.classList.toggle("is-open", open);
        toggle.setAttribute("aria-expanded", String(open));
        toggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
    }

    toggle.addEventListener("click", function () {
        setOpen(toggle.getAttribute("aria-expanded") !== "true");
    });

    document.addEventListener("keydown", function (e) {
        if (e.key === "Escape" && nav.classList.contains("is-open")) {
            setOpen(false);
            toggle.focus();
        }
    });

    document.addEventListener("click", function (e) {
        if (!nav.contains(e.target)) setOpen(false);
    });
})();
