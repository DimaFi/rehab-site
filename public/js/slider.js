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
    
    // Функции для работы с PDF документами
    window.previewPDF = function(pdfUrl) {
        const modal = document.getElementById('pdfModal');
        const iframe = document.getElementById('pdfViewer');
        const title = document.getElementById('pdfModalTitle');
        const fullPdfLink = document.getElementById('fullPdfLink');
        
        // Устанавливаем URL для iframe
        iframe.src = pdfUrl;
        
        // Обновляем заголовок и ссылку
        const fileName = pdfUrl.split('/').pop().replace('.pdf', '');
        title.textContent = `Предпросмотр: ${fileName}`;
        fullPdfLink.href = pdfUrl;
        
        // Показываем модальное окно
        modal.style.display = 'block';
        
        // Блокируем прокрутку страницы
        document.body.style.overflow = 'hidden';
    };
    
    window.closePDFModal = function() {
        const modal = document.getElementById('pdfModal');
        const iframe = document.getElementById('pdfViewer');
        
        // Скрываем модальное окно
        modal.style.display = 'none';
        
        // Очищаем iframe
        iframe.src = '';
        
        // Восстанавливаем прокрутку страницы
        document.body.style.overflow = 'auto';
    };
    
    // Закрытие модального окна по клику вне его
    document.getElementById('pdfModal').addEventListener('click', function(e) {
        if (e.target === this) {
            closePDFModal();
        }
    });
    
    // Закрытие модального окна по клавише Escape
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            const modal = document.getElementById('pdfModal');
            if (modal.style.display === 'block') {
                closePDFModal();
            }
        }
    });
    
    // Слайдер "Почему выбирают нас"
    let currentWhySlide = 0;
    const whySlides = document.querySelectorAll('.why-slide');
    const whyDots = document.querySelectorAll('.why-dot');
    const totalWhySlides = whySlides.length;
    
    function showWhySlide(index) {
        // Скрываем все слайды
        whySlides.forEach(slide => slide.classList.remove('active'));
        whyDots.forEach(dot => dot.classList.remove('active'));
        
        // Показываем текущий слайд
        whySlides[index].classList.add('active');
        whyDots[index].classList.add('active');
        
        currentWhySlide = index;
    }
    
    function changeWhySlide(direction) {
        const next = (currentWhySlide + direction + totalWhySlides) % totalWhySlides;
        showWhySlide(next);
    }
    
    function goToWhySlide(index) {
        showWhySlide(index);
    }
    
    // Автоматическое переключение слайдов "Почему выбирают нас"
    if (totalWhySlides > 0) {
        setInterval(() => {
            changeWhySlide(1);
        }, 6000); // Переключение каждые 6 секунд
    }
    
    // Обработка клавиш стрелок для слайдера "Почему выбирают нас"
    document.addEventListener('keydown', function(e) {
        if (e.key === 'ArrowLeft') {
            changeWhySlide(-1);
        } else if (e.key === 'ArrowRight') {
            changeWhySlide(1);
        }
    });
    
    // Делаем функции глобально доступными
    window.changeWhySlide = changeWhySlide;
    window.goToWhySlide = goToWhySlide;
});
