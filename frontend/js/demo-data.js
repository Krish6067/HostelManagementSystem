// demo-data.js
// Fake data simulating database records for the prototype

const mockData = {
    students: [
        {
            id: '251033110',
            name: 'KRISH THAKUR',
            course: 'B.Tech CSE',
            year: '2nd Year',
            hostel: 'Boys Hostel - 2',
            room: 'L 2',
            roomType: 'double Sharing',
            phone: '+91 9876543210',
            parentId: 'PAR20260045'
        }
    ],
    parents: [
        {
            id: 'PAR20260045',
            name: 'Mr. Rajesh Sharma',
            studentId: 'STU20260045',
            phone: '+91 9123456789'
        }
    ],
    wardens: [
        {
            id: 'WAR001',
            name: 'Dr. A. K. Singh',
            hostel: 'Boys Hostel - 2'
        }
    ],
    security: [
        {
            id: 'SEC001',
            name: 'Ramesh Kumar',
            location: 'Main Gate'
        }
    ],
    outpasses: [
        {
            id: 'OP20260124',
            studentId: 'STU20260045',
            destination: 'Chandigarh',
            reason: 'Family Visit',
            type: 'Weekend Outpass',
            departureDate: '2026-09-12T10:00:00',
            returnDate: '2026-09-14T20:00:00',
            parentStatus: 'APPROVED', // PENDING, APPROVED, REJECTED
            wardenStatus: 'PENDING',  // LOCKED, PENDING, APPROVED, REJECTED
            finalStatus: 'PENDING',   // PENDING, ACTIVE, COMPLETED, EXPIRED, REJECTED
            qrStatus: 'LOCKED',       // LOCKED, AVAILABLE
            rejectionReason: null
        }
    ],
    notifications: [
        {
            id: 1,
            userId: 'STU20260045',
            title: 'Outpass Approved by Parent',
            message: 'Your outpass request to Chandigarh has been approved by your parent.',
            date: '2026-09-10T14:30:00',
            read: false
        }
    ],
    complaints: [
        {
            id: 'CMP001',
            userId: 'STU20260045',
            title: 'Fan not working',
            description: 'The ceiling fan in room 214 is making a weird noise and not spinning fast.',
            status: 'PENDING',
            date: '2026-09-28T09:00:00'
        }
    ],
    notices: [
        {
            id: 'NOT001',
            title: 'Hostel Maintenance',
            content: 'Water supply will be cut off on Sunday from 10 AM to 2 PM for tank cleaning.',
            date: '2026-09-29T10:00:00'
        },
        {
            id: 'NOT002',
            title: 'Upcoming Holidays',
            content: 'Please ensure to apply for outpass well in advance for the upcoming Diwali holidays.',
            date: '2026-09-25T14:00:00'
        }
    ]
};

// Simple local storage persistence wrapper for demo purposes
function getDB() {
    const dbStr = localStorage.getItem('hms_db');
    if (!dbStr) {
        localStorage.setItem('hms_db', JSON.stringify(mockData));
        return mockData;
    }
    const db = JSON.parse(dbStr);
    let updated = false;
    if (!db.complaints) { db.complaints = mockData.complaints; updated = true; }
    if (!db.notices) { db.notices = mockData.notices; updated = true; }
    if (updated) localStorage.setItem('hms_db', JSON.stringify(db));
    return db;
}

function saveDB(data) {
    localStorage.setItem('hms_db', JSON.stringify(data));
}

function resetDB() {
    localStorage.removeItem('hms_db');
    return getDB();
}

window.HMS_DB = {
    get: getDB,
    save: saveDB,
    reset: resetDB
};
