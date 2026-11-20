// outpass.js - Core business logic for outpasses

// Define the core state machine for outpasses
const OutpassStatus = {
    PENDING_PARENT: 'PENDING_PARENT',
    PARENT_APPROVED: 'PARENT_APPROVED',
    PARENT_REJECTED: 'PARENT_REJECTED',
    PENDING_WARDEN: 'PENDING_WARDEN', // Equivalent to PARENT_APPROVED waiting for Warden
    WARDEN_APPROVED: 'WARDEN_APPROVED',
    WARDEN_REJECTED: 'WARDEN_REJECTED',
    ACTIVE: 'ACTIVE',
    COMPLETED: 'COMPLETED',
    EXPIRED: 'EXPIRED'
};

function calculateOutpassState(outpass) {
    if (outpass.parentStatus === 'REJECTED') {
        return {
            wardenLock: true,
            qrLock: true,
            status: OutpassStatus.PARENT_REJECTED,
            display: 'Rejected by Parent'
        };
    }

    if (outpass.parentStatus === 'PENDING') {
        return {
            wardenLock: true,
            qrLock: true,
            status: OutpassStatus.PENDING_PARENT,
            display: 'Waiting for Parent Approval'
        };
    }

    if (outpass.parentStatus === 'APPROVED') {
        if (outpass.wardenStatus === 'PENDING' || outpass.wardenStatus === 'LOCKED') {
            return {
                wardenLock: false,
                qrLock: true,
                status: OutpassStatus.PENDING_WARDEN,
                display: 'Waiting for Warden Approval'
            };
        }
        
        if (outpass.wardenStatus === 'REJECTED') {
            return {
                wardenLock: false,
                qrLock: true,
                status: OutpassStatus.WARDEN_REJECTED,
                display: 'Rejected by Warden'
            };
        }
        
        if (outpass.wardenStatus === 'APPROVED') {
            // Check final statuses
            if (outpass.finalStatus === 'ACTIVE') {
                return { wardenLock: false, qrLock: false, status: OutpassStatus.ACTIVE, display: 'Active' };
            }
            if (outpass.finalStatus === 'COMPLETED') {
                return { wardenLock: false, qrLock: true, status: OutpassStatus.COMPLETED, display: 'Completed' };
            }
            
            return {
                wardenLock: false,
                qrLock: false, // QR is available!
                status: OutpassStatus.WARDEN_APPROVED,
                display: 'Approved - QR Available'
            };
        }
    }
    
    return { wardenLock: true, qrLock: true, status: 'UNKNOWN', display: 'Unknown' };
}

function submitOutpass(studentId, data) {
    const db = window.HMS_DB.get();
    
    const newOutpass = {
        id: 'OP' + Date.now(),
        studentId: studentId,
        destination: data.destination,
        reason: data.reason,
        type: data.type,
        departureDate: data.departureDate,
        returnDate: data.returnDate,
        parentStatus: 'PENDING',
        wardenStatus: 'LOCKED', // Enforcing business rule
        finalStatus: 'PENDING',
        qrStatus: 'LOCKED',
        createdAt: new Date().toISOString()
    };
    
    db.outpasses.push(newOutpass);
    
    // Add notification for parent
    const student = db.students.find(s => s.id === studentId);
    if(student) {
        db.notifications.push({
            id: Date.now(),
            userId: student.parentId,
            title: 'New Outpass Request',
            message: `${student.name} has submitted an outpass request for ${data.destination}.`,
            date: new Date().toISOString(),
            read: false
        });
    }

    window.HMS_DB.save(db);
    return newOutpass;
}

function parentApproveOutpass(outpassId) {
    const db = window.HMS_DB.get();
    const idx = db.outpasses.findIndex(o => o.id === outpassId);
    if (idx === -1) return false;

    const outpass = db.outpasses[idx];
    if (outpass.parentStatus !== 'PENDING') return false;

    const student = (db.students || []).find(s => s.id === outpass.studentId);
    const studentName = student?.name || outpass.studentName || `Student ${outpass.studentId || ''}`.trim();
    if (!Array.isArray(db.notifications)) db.notifications = [];

    outpass.parentStatus = 'APPROVED';
    outpass.wardenStatus = 'PENDING'; // Unlocks warden

    const now = new Date().toISOString();
    db.notifications.push({
        id: Date.now(),
        userId: outpass.studentId,
        title: 'Parent Approved Outpass',
        message: `Your outpass to ${outpass.destination} was approved by your parent. Waiting for Warden.`,
        date: now,
        read: false
    });
    db.notifications.push({
        id: Date.now() + 1,
        userId: 'WAR001',
        title: 'Parent Approval Received',
        message: `${studentName}'s parent has approved the outpass. Ready for your review.`,
        date: now,
        read: false
    });

    window.HMS_DB.save(db);
    return true;
}

function wardenApproveOutpass(outpassId) {
    const db = window.HMS_DB.get();
    const idx = db.outpasses.findIndex(o => o.id === outpassId);
    if (idx !== -1) {
        // Enforce rule: Warden cannot approve if parent hasn't approved
        if (db.outpasses[idx].parentStatus !== 'APPROVED') {
            console.error("Warden cannot approve. Parent approval pending/rejected.");
            return false;
        }

        db.outpasses[idx].wardenStatus = 'APPROVED';
        db.outpasses[idx].qrStatus = 'AVAILABLE';
        
        // Notify student
        db.notifications.push({
            id: Date.now(),
            userId: db.outpasses[idx].studentId,
            title: 'Outpass Issued',
            message: `Your outpass to ${db.outpasses[idx].destination} is fully approved. QR is available.`,
            date: new Date().toISOString(),
            read: false
        });

        window.HMS_DB.save(db);
        return true;
    }
    return false;
}

// Additional functions for rejection would go here.
