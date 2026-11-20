// sections.js - Shared section navigation for all dashboards

function initSections(onSectionChange) {
    const navItems = document.querySelectorAll('.sidebar-nav .nav-item[data-section]');
    const sections = document.querySelectorAll('.section-content');

    function showSection(sectionId) {
        sections.forEach(s => s.style.display = 'none');
        navItems.forEach(i => i.classList.remove('active'));

        const target = document.getElementById('section-' + sectionId);
        if (target) target.style.display = 'block';

        const activeNav = document.querySelector(`.nav-item[data-section="${sectionId}"]`);
        if (activeNav) activeNav.classList.add('active');

        if (onSectionChange) onSectionChange(sectionId);
    }

    navItems.forEach(item => {
        item.addEventListener('click', e => {
            e.preventDefault();
            showSection(item.getAttribute('data-section'));
        });
    });

    // Show first section (dashboard) by default
    const firstSection = document.querySelector('.nav-item[data-section]');
    if (firstSection) showSection(firstSection.getAttribute('data-section'));
}
