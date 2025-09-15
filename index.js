
document.addEventListener('DOMContentLoaded', () => {
    const mobileMenuButton = document.getElementById('mobile-menu-button');
    const mobileMenu = document.getElementById('mobile-menu');
    const header = document.getElementById('main-header');

    // Toggle mobile menu
    if (mobileMenuButton && mobileMenu) {
        mobileMenuButton.addEventListener('click', () => {
            mobileMenu.classList.toggle('hidden');
            document.body.classList.toggle('mobile-menu-open');
        });

        // Close menu if a link is clicked
        mobileMenu.addEventListener('click', (e) => {
            if (e.target.tagName === 'A') {
                mobileMenu.classList.add('hidden');
                document.body.classList.remove('mobile-menu-open');
            }
        });
    }

    // Change header background on scroll
    if(header) {
        window.addEventListener('scroll', () => {
            if (window.scrollY > 20) {
                header.classList.add('bg-black/50', 'backdrop-blur-md', 'border-b', 'border-gray-800/50');
            } else {
                header.classList.remove('bg-black/50', 'backdrop-blur-md', 'border-b', 'border-gray-800/50');
            }
        });
    }
    
    // Disable right-click context menu
    document.addEventListener('contextmenu', event => event.preventDefault());
});
