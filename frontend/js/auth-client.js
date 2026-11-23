document.addEventListener('DOMContentLoaded', () => {
    const form = document.querySelector('form');
    if (!form) return;
    const role = location.pathname.split('/').filter(Boolean)[0];
    const inputs = form.querySelectorAll('input');
    const identifier = form.querySelector('input[type="text"], input[type="email"]') || inputs[0];
    const password = form.querySelector('input[type="password"]');
    const message = document.createElement('p');
    message.id = 'loginMessage';
    message.setAttribute('role', 'alert');
    message.style.color = 'var(--color-danger)';
    message.style.minHeight = '1.5em';
    form.appendChild(message);
    form.addEventListener('submit', async event => {
        event.preventDefault();
        message.textContent = '';
        const button = form.querySelector('button[type="submit"]');
        if (button) button.disabled = true;
        try {
            const response = await fetch('/api/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'same-origin',
                body: JSON.stringify({ role, identifier: identifier?.value || '', password: password?.value || '' })
            });
            const result = await response.json();
            if (!response.ok) throw new Error(result.error || 'Login failed.');
            location.replace(`/${role}/dashboard.html`);
        } catch (error) {
            message.textContent = error instanceof TypeError
                ? 'Open this portal using run-local.ps1. Direct file access does not authenticate.'
                : error.message;
        } finally {
            if (button) button.disabled = false;
        }
    });
});
