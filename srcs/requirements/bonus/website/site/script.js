// DOM Elements
const navLinks = document.querySelectorAll('.nav-link');
const sections = document.querySelectorAll('.section');
let pageVisits = parseInt(localStorage.getItem('pageVisits') || '0');

// Initialize
document.addEventListener('DOMContentLoaded', function () {
    initializeNavigation();
    incrementPageVisits();
    animateStats();
});

// Navigation handling
function initializeNavigation() {
    navLinks.forEach(link => {
        link.addEventListener('click', function (e) {
            e.preventDefault();

            const sectionId = this.getAttribute('data-section');
            showSection(sectionId);

            // Update active nav link
            navLinks.forEach(l => l.classList.remove('active'));
            this.classList.add('active');

            // Update URL
            window.history.pushState({ section: sectionId }, '', `#${sectionId}`);
        });
    });

    // Handle browser back/forward buttons
    window.addEventListener('popstate', function (e) {
        if (e.state && e.state.section) {
            showSection(e.state.section);
        }
    });

    // Load section from URL hash on page load
    const hash = window.location.hash.slice(1);
    if (hash && document.getElementById(hash)) {
        showSection(hash);
    }
}

// Show specific section
function showSection(sectionId) {
    sections.forEach(section => {
        section.classList.remove('active');
    });

    const targetSection = document.getElementById(sectionId);
    if (targetSection) {
        targetSection.classList.add('active');
    }
}

// Scroll to section smoothly
function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        showSection(sectionId);

        // Update nav link
        navLinks.forEach(link => link.classList.remove('active'));
        const activeLink = document.querySelector(`[data-section="${sectionId}"]`);
        if (activeLink) {
            activeLink.classList.add('active');
        }

        // Scroll to top to see the section better
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}

// Increment page visits
function incrementPageVisits() {
    pageVisits++;
    localStorage.setItem('pageVisits', pageVisits.toString());
    document.getElementById('requests').textContent = pageVisits;
}

// Animate stats on page load
function animateStats() {
    const servicesActive = 6; // nginx, wordpress, mariadb, redis, adminer, vsftpd
    animateCounter('uptime', 0, servicesActive, 1000);
}

// Animate counter
function animateCounter(elementId, start, end, duration) {
    const element = document.getElementById(elementId);
    const startTime = performance.now();

    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const current = Math.floor(start + (end - start) * progress);

        element.textContent = current;

        if (progress < 1) {
            requestAnimationFrame(update);
        }
    }

    requestAnimationFrame(update);
}

// Add smooth scroll behavior to hash links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const href = this.getAttribute('href');
        if (href !== '#') {
            e.preventDefault();
        }
    });
});

// Log page load info
console.log('%c42 Inception - Docker Project', 'color: #42b983; font-size: 16px; font-weight: bold;');
console.log('%cServices: Nginx, WordPress, MariaDB, Redis, Adminer, VSFTPD', 'color: #2c3e50; font-size: 12px;');
console.log('%cBuilt with Docker Compose on Alpine Linux', 'color: #7f8c8d; font-size: 12px;');
