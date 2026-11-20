(() => {
    const expectedRole = location.pathname.split('/').filter(Boolean)[0];
    const setText = (id, value) => {
        const element = document.getElementById(id);
        if (element && value !== undefined && value !== null && String(value).length) element.textContent = String(value);
    };
    const applyAccountProfile = session => {
        const profile = session.profile || {};
        const initials = String(session.name || '').split(/\s+/).filter(Boolean).slice(0, 2).map(part => part[0]).join('').toUpperCase();
        setText('headerName', session.name);
        setText('headerAvatar', initials);
        setText('welcomeName', String(session.name || '').split(/\s+/)[0]);
        setText('profileAvatar', initials);
        setText('profileName', session.name);
        setText('profileId', session.id || session.email);
        setText('pProfName', session.name);
        setText('pProfId', session.id || session.email);
        setText('profName', session.name);
        setText('profId', session.id || session.email);

        if (session.role === 'student') {
            setText('pProfCourse', profile.course);
            setText('profCourse', profile.course);
            setText('pProfYear', profile.year);
            setText('profYear', profile.year);
            setText('pProfPhone', profile.phone);
            setText('profPhone', profile.phone);
            setText('pProfHostel', profile.hostel);
            setText('profHostel', profile.hostel);
            setText('pProfRoom', profile.room);
            setText('profRoom', profile.room);
            setText('pProfRoomType', profile.bed ? `Bed ${profile.bed}` : '');
            setText('pProfParentId', profile.parentEmail);
            setText('statRoom', profile.room);
            setText('roomNo', profile.room);
            setText('statHostel', profile.hostel);
            setText('roomHostel', profile.hostel);
        } else if (session.role === 'parent') {
            setText('pProfPhone', profile.phone);
            setText('pProfChild', profile.studentName);
            setText('childName', profile.studentName);
            setText('profChildName', profile.studentName);
            setText('childId', profile.studentId);
            setText('profChildId', profile.studentId);
            setText('childCourse', profile.course);
            setText('profChildCourse', profile.course);
            setText('childYear', profile.year);
            setText('profChildYear', profile.year);
            setText('childHostel', profile.hostel);
            setText('profChildHostel', profile.hostel);
            setText('childRoom', profile.room);
            setText('profChildRoom', profile.room);
        } else if (session.role === 'warden') {
            setText('pProfHostel', profile.hostel);
            setText('pProfDesignation', profile.designation);
            setText('pProfPhone', profile.phone);
        } else if (session.role === 'security') {
            setText('pProfLocation', profile.post);
            setText('pProfHostel', profile.hostel);
            setText('pProfPhone', profile.phone);
            setText('pProfShift', profile.shift);
        }
    };
    fetch('/api/session', { credentials: 'same-origin', cache: 'no-store' })
        .then(async response => {
            if (!response.ok) throw new Error('unauthenticated');
            const session = await response.json();
            if (session.role !== expectedRole) throw new Error('wrong role');
            sessionStorage.setItem('hms_auth_profile', JSON.stringify(session));
            if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => setTimeout(() => applyAccountProfile(session), 0), { once: true });
            else setTimeout(() => applyAccountProfile(session), 0);
        })
        .catch(() => location.replace(`/${expectedRole}/login.html`));

    document.addEventListener('click', event => {
        const link = event.target.closest('a');
        if (!link || !link.getAttribute('href')?.endsWith('../index.html')) return;
        event.preventDefault();
        fetch('/api/logout', { method: 'POST', credentials: 'same-origin' })
            .finally(() => location.replace('/index.html'));
    });
})();
