// main.js - Core UI functionality

document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    initSidebar();
    initModals();
    initNotifications();
    initNavSections();
});

function initTheme() {
    const key = 'hms_theme';
    const apply = theme => {
        document.documentElement.dataset.theme = theme;
        document.body.classList.toggle('dark-theme', theme === 'dark');
        const button = document.getElementById('theme-toggle');
        if (button) {
            button.textContent = theme === 'dark' ? '☀️ Light mode' : '🌙 Dark mode';
            button.setAttribute('aria-pressed', String(theme === 'dark'));
        }
        document.querySelectorAll('input[name="theme"]').forEach(input => {
            input.checked = input.value === theme || (theme === 'light' && input.value !== 'dark' && input.closest('label')?.textContent.toLowerCase().includes('light')) || (theme === 'dark' && input.closest('label')?.textContent.toLowerCase().includes('dark'));
        });
    };
    const header = document.querySelector('.top-header .header-right');
    if (header && !document.getElementById('theme-toggle')) {
        const button = document.createElement('button');
        button.id = 'theme-toggle';
        button.type = 'button';
        button.className = 'btn btn-secondary theme-toggle';
        button.addEventListener('click', () => {
            const next = document.body.classList.contains('dark-theme') ? 'light' : 'dark';
            localStorage.setItem(key, next);
            apply(next);
        });
        header.prepend(button);
    }
    document.querySelectorAll('input[name="theme"]').forEach(input => input.addEventListener('change', () => {
        if (!input.checked) return;
        const label = input.closest('label')?.textContent.toLowerCase() || '';
        const theme = input.value === 'dark' || label.includes('dark') ? 'dark' : 'light';
        localStorage.setItem(key, theme);
        apply(theme);
    }));
    apply(localStorage.getItem(key) === 'dark' ? 'dark' : 'light');
}

function initSidebar() {
    const menuToggle = document.getElementById('menu-toggle');
    const sidebar = document.getElementById('sidebar');
    
    // Create overlay
    const overlay = document.createElement('div');
    overlay.className = 'sidebar-overlay';
    document.body.appendChild(overlay);

    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', () => {
            sidebar.classList.toggle('open');
            overlay.classList.toggle('active');
        });

        overlay.addEventListener('click', () => {
            sidebar.classList.remove('open');
            overlay.classList.remove('active');
        });
    }
}

function initModals() {
    const modals = document.querySelectorAll('.modal-backdrop');
    const closeBtns = document.querySelectorAll('.modal-close, [data-dismiss="modal"]');

    // Setup close buttons
    closeBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modal = e.target.closest('.modal-backdrop');
            if (modal) {
                closeModal(modal.id);
            }
        });
    });

    // Close on click outside
    modals.forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeModal(modal.id);
            }
        });
    });
}

function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('active');
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
    }
}

function initNotifications() {
    const notifToggle = document.getElementById('notification-toggle');
    const notifPanel = document.getElementById('notification-panel');

    if (notifToggle && notifPanel) {
        notifToggle.addEventListener('click', (e) => {
            e.stopPropagation();
            notifPanel.classList.toggle('active');
        });

        document.addEventListener('click', (e) => {
            if (!notifToggle.contains(e.target) && !notifPanel.contains(e.target)) {
                notifPanel.classList.remove('active');
            }
        });
    }
}

// Utility function to format dates
function formatDate(dateString) {
    const options = { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' };
    return new Date(dateString).toLocaleDateString('en-US', options);
}

// Global user session (mock)
function getCurrentUser() {
    return JSON.parse(sessionStorage.getItem('currentUser')) || null;
}

function loginUser(role, id) {
    const user = { role, id };
    sessionStorage.setItem('currentUser', JSON.stringify(user));
    window.location.href = `../${role}/dashboard.html`;
}

function logoutUser() {
    sessionStorage.removeItem('currentUser');
    window.location.href = '../index.html';
}
