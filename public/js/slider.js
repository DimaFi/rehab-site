// Слайдер для акций
document.addEventListener('DOMContentLoaded', function() {
    // Инициализация слайдера акций (правый)
    initSlider('.slider-container', '.slide', '.dot', '.prev-btn', '.next-btn');
    
    function initSlider(containerSelector, slideSelector, dotSelector, prevBtnSelector, nextBtnSelector) {
        const container = document.querySelector(containerSelector);
        if (!container) return;
        
        const slides = container.querySelectorAll(slideSelector);
        const dots = container.querySelectorAll(dotSelector);
        const prevBtn = container.querySelector(prevBtnSelector);
        const nextBtn = container.querySelector(nextBtnSelector);
        
        let currentSlide = 0;
        const totalSlides = slides.length;
        
        if (totalSlides === 0) return;
        
        // Функция для показа слайда
        function showSlide(index) {
            // Скрываем все слайды
            slides.forEach(slide => slide.classList.remove('active'));
            dots.forEach(dot => dot.classList.remove('active'));
            
            // Показываем текущий слайд
            slides[index].classList.add('active');
            dots[index].classList.add('active');
            
            currentSlide = index;
        }
        
        // Функция для следующего слайда
        function nextSlide() {
            const next = (currentSlide + 1) % totalSlides;
            showSlide(next);
        }
        
        // Функция для предыдущего слайда
        function prevSlide() {
            const prev = (currentSlide - 1 + totalSlides) % totalSlides;
            showSlide(prev);
        }
        
        // Обработчики событий для кнопок
        if (nextBtn) {
            nextBtn.addEventListener('click', nextSlide);
        }
        
        if (prevBtn) {
            prevBtn.addEventListener('click', prevSlide);
        }
        
        // Обработчики событий для точек
        dots.forEach((dot, index) => {
            dot.addEventListener('click', () => showSlide(index));
        });
        
        // Автоматическое переключение слайдов
        setInterval(nextSlide, 5000);
    }
    
    // Обработка клавиш стрелок
    document.addEventListener('keydown', function(e) {
        const activeSlide = document.querySelector('.slide.active');
        if (!activeSlide) return;
        
        const container = activeSlide.closest('.slider-container');
        const slides = container.querySelectorAll('.slide');
        const dots = container.querySelectorAll('.dot');
        const currentIndex = Array.from(slides).indexOf(activeSlide);
        
        if (e.key === 'ArrowLeft') {
            const prev = (currentIndex - 1 + slides.length) % slides.length;
            slides.forEach(slide => slide.classList.remove('active'));
            dots.forEach(dot => dot.classList.remove('active'));
            slides[prev].classList.add('active');
            dots[prev].classList.add('active');
        } else if (e.key === 'ArrowRight') {
            const next = (currentIndex + 1) % slides.length;
            slides.forEach(slide => slide.classList.remove('active'));
            dots.forEach(dot => dot.classList.remove('active'));
            slides[next].classList.add('active');
            dots[next].classList.add('active');
        }
    });
});
