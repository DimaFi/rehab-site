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
        if (!modal || !iframe || !title || !fullPdfLink) return;
        
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
        if (!modal || !iframe) return;
        
        // Скрываем модальное окно
        modal.style.display = 'none';
        
        // Очищаем iframe
        iframe.src = '';
        
        // Восстанавливаем прокрутку страницы
        document.body.style.overflow = 'auto';
    };
    
    // Закрытие модального окна по клику вне его
    const pdfModalEl = document.getElementById('pdfModal');
    if (pdfModalEl) {
        pdfModalEl.addEventListener('click', function(e) {
            if (e.target === this) {
                closePDFModal();
            }
        });
    }
    
    // Закрытие модального окна по клавише Escape
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            const modal = document.getElementById('pdfModal');
            if (modal && modal.style.display === 'block') {
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

    // Слайдер специалистов (4 видимых, сдвиг по 1)

    const specialistsMap = new WeakMap();
    let specialistsDelegationBound = false;

    function bindSpecialistsDelegation() {
        if (specialistsDelegationBound) return;
        specialistsDelegationBound = true;
        document.addEventListener('click', (e) => {
            const btn = e.target.closest('.specialists-prev, .specialists-next');
            if (!btn) return;
            const slider = btn.closest('.specialists-slider');
            if (!slider) return;
            const api = specialistsMap.get(slider);
            if (!api) return;
            e.preventDefault();
            e.stopPropagation();
            if (btn.classList.contains('specialists-prev')) api.prev();
            else api.next();
        });
    }

    function initSpecialistsSlider() {
        const sliders = document.querySelectorAll('.specialists-slider');
        if (!sliders.length) return;
        bindSpecialistsDelegation();
        sliders.forEach(setupSlider);
    }

    function setupSlider(slider) {
        const viewport = slider.querySelector('.specialists-viewport');
        const track = slider.querySelector('.specialists-track');
        const prevBtn = slider.querySelector('.specialists-prev');
        const nextBtn = slider.querySelector('.specialists-next');
        const cards = Array.from(track.querySelectorAll('.specialist-card'));
        if (cards.length === 0) return;

        function getVisibleCount() {
            const w = window.innerWidth;
            if (w <= 480) return 1;
            if (w <= 768) return 2;
            return Number(slider.getAttribute('data-visible') || 4);
        }
        let visible = getVisibleCount();
        let stepPx = 0; // точный шаг с учетом gap

        // Клонируем для бесконечной прокрутки
        let prependClones = cards.slice(-visible).map(n => n.cloneNode(true));
        let appendClones = cards.slice(0, visible).map(n => n.cloneNode(true));
        prependClones.forEach(n => track.insertBefore(n, track.firstChild));
        appendClones.forEach(n => track.appendChild(n));

        let allItems = Array.from(track.children);
        let index = visible; // стартовая позиция — первый реальный элемент

        function computeStepPx() {
            const items = track.querySelectorAll('.specialist-card');
            if (items.length <= 1) {
                const rect = items[0]?.getBoundingClientRect();
                return rect ? rect.width : 0;
            }
            const first = items[0].getBoundingClientRect();
            const second = items[1].getBoundingClientRect();
            const dx = Math.round(second.left - first.left);
            return Math.abs(dx) || first.width; //fallback
        }

        function updateTransform(animate = true) {
            if (!animate) track.style.transition = 'none';
            else track.style.transition = 'transform .35s ease';
            const offset = -index * stepPx;
            track.style.transform = `translateX(${offset}px)`;
        }

        function onResize() {
            const newVisible = getVisibleCount();
            if (newVisible !== visible) {
                // пересоздаем клоны при изменении видимых карточек
                // удалить старые клоны
                allItems.forEach((node, idx) => {
                    // реальные узлы имеют класс specialist-card и присутствуют в исходном массиве cards
                });
                // восстановить трек в исходное состояние (оставить только реальные карточки)
                track.innerHTML = '';
                cards.forEach(n => track.appendChild(n));
                visible = newVisible;
                prependClones = cards.slice(-visible).map(n => n.cloneNode(true));
                appendClones = cards.slice(0, visible).map(n => n.cloneNode(true));
                prependClones.forEach(n => track.insertBefore(n, track.firstChild));
                appendClones.forEach(n => track.appendChild(n));
                allItems = Array.from(track.children);
                index = visible;
            }
            stepPx = computeStepPx();
            updateTransform(false);
        }

        function goNext() {
            index += 1;
            updateTransform(true);
        }

        function goPrev() {
            index -= 1;
            updateTransform(true);
        }

        track.addEventListener('transitionend', () => {
            // Если ушли в правые клоны, мгновенно перекидываем к реальным
            if (index >= allItems.length - visible) {
                index = visible;
                updateTransform(false);
            }
            // Если ушли в левые клоны, перекидываем в конец реальных
            if (index < visible) {
                index = allItems.length - visible * 2;
                updateTransform(false);
            }
        });

        // прямые обработчики (на случай отключения делегирования)
        nextBtn && nextBtn.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); goNext(); });
        prevBtn && prevBtn.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); goPrev(); });

        window.addEventListener('resize', () => {
            // дождемся переназначения layout
            requestAnimationFrame(onResize);
        });
        // первичный расчет после рендера
        requestAnimationFrame(() => {
            onResize();
            updateTransform(false);
        });

        // сохранить API в карту
        specialistsMap.set(slider, { next: goNext, prev: goPrev });
    }
    // Инициализируем после объявления всех вспомогательных сущностей
    initSpecialistsSlider();

    // Блокируем переход только для карточек-заглушек (href="#")
    document.addEventListener('click', function(e) {
        const card = e.target.closest('.team-card');
        if (!card) return;
        const href = card.getAttribute('href');
        if (!href || href === '#') {
            e.preventDefault();
        }
    });
    
    // Инициализация галереи фотографий (с задержкой для загрузки изображений)
    setTimeout(function() {
        initGallerySlider();
    }, 300);
});

// Галерея фотографий центра
function initGallerySlider() {
    const slider = document.getElementById('gallerySlider');
    if (!slider) return;
    
    const track = slider.querySelector('.gallery-track');
    const images = track.querySelectorAll('.gallery-image');
    const prevBtn = slider.querySelector('.gallery-prev');
    const nextBtn = slider.querySelector('.gallery-next');
    
    if (images.length === 0) return;
    
    let currentIndex = 0;
    const visibleCount = window.innerWidth <= 768 ? 2 : 4;
    
    function updateSlider() {
        if (images.length === 0) return;
        const imageWidth = images[0].offsetWidth;
        const gap = 20;
        const maxIndex = Math.max(0, images.length - visibleCount);
        currentIndex = Math.min(currentIndex, maxIndex);
        const offset = -(currentIndex * (imageWidth + gap));
        track.style.transform = `translateX(${offset}px)`;
    }
    
    function nextSlide() {
        const maxIndex = Math.max(0, images.length - visibleCount);
        currentIndex = (currentIndex + 1) % (maxIndex + 1);
        updateSlider();
    }
    
    function prevSlide() {
        const maxIndex = Math.max(0, images.length - visibleCount);
        currentIndex = (currentIndex - 1 + (maxIndex + 1)) % (maxIndex + 1);
        updateSlider();
    }
    
    if (nextBtn) nextBtn.addEventListener('click', nextSlide);
    if (prevBtn) prevBtn.addEventListener('click', prevSlide);
    
    // Обработчики клика на изображения для открытия в полноэкранном режиме
    images.forEach((img, index) => {
        img.addEventListener('click', function() {
            window.openGalleryModal(index);
        });
    });
    
    // Обработка изменения размера окна
    let resizeTimer;
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function() {
            updateSlider();
        }, 250);
    });
    
    // Инициализация после загрузки изображений
    const imagesLoaded = Array.from(images);
    let loadedCount = 0;
    imagesLoaded.forEach(function(img) {
        if (img.complete) {
            loadedCount++;
        } else {
            img.addEventListener('load', function() {
                loadedCount++;
                if (loadedCount === imagesLoaded.length) {
                    updateSlider();
                }
            });
        }
    });
    
    if (loadedCount === imagesLoaded.length) {
        // Все изображения уже загружены
        setTimeout(updateSlider, 100);
    } else {
        // Ждем загрузки всех изображений
        setTimeout(updateSlider, 500);
    }
}

let currentGalleryIndex = 0;
let galleryImagesList = [];

// Глобальные функции для модального окна галереи
window.openGalleryModal = function(index) {
    const modal = document.getElementById('galleryModal');
    const modalImage = document.getElementById('galleryModalImage');
    const currentSpan = document.getElementById('galleryModalCurrent');
    const totalSpan = document.getElementById('galleryModalTotal');
    
    if (!modal || !modalImage) return;
    
    // Инициализируем список изображений, если еще не сделано
    if (galleryImagesList.length === 0) {
        const images = document.querySelectorAll('.gallery-image');
        galleryImagesList = Array.from(images).map(img => img.src);
    }
    
    currentGalleryIndex = index;
    modalImage.src = galleryImagesList[index];
    if (currentSpan) currentSpan.textContent = index + 1;
    if (totalSpan) totalSpan.textContent = galleryImagesList.length;
    
    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
};

window.closeGalleryModal = function() {
    const modal = document.getElementById('galleryModal');
    if (!modal) return;
    
    modal.style.display = 'none';
    document.body.style.overflow = 'auto';
};

window.nextGalleryImage = function() {
    if (galleryImagesList.length === 0) return;
    currentGalleryIndex = (currentGalleryIndex + 1) % galleryImagesList.length;
    const modalImage = document.getElementById('galleryModalImage');
    const currentSpan = document.getElementById('galleryModalCurrent');
    if (modalImage) modalImage.src = galleryImagesList[currentGalleryIndex];
    if (currentSpan) currentSpan.textContent = currentGalleryIndex + 1;
};

window.prevGalleryImage = function() {
    if (galleryImagesList.length === 0) return;
    currentGalleryIndex = (currentGalleryIndex - 1 + galleryImagesList.length) % galleryImagesList.length;
    const modalImage = document.getElementById('galleryModalImage');
    const currentSpan = document.getElementById('galleryModalCurrent');
    if (modalImage) modalImage.src = galleryImagesList[currentGalleryIndex];
    if (currentSpan) currentSpan.textContent = currentGalleryIndex + 1;
};

// Закрытие модального окна по клику вне изображения и по клавишам
document.addEventListener('DOMContentLoaded', function() {
    // Инициализация массива изображений для модального окна
    const images = document.querySelectorAll('.gallery-image');
    galleryImagesList = Array.from(images).map(img => img.src);
    
    const modal = document.getElementById('galleryModal');
    if (modal) {
        modal.addEventListener('click', function(e) {
            if (e.target === modal) {
                window.closeGalleryModal();
            }
        });
    }
    
    // Закрытие по клавише Escape и навигация по стрелкам
    document.addEventListener('keydown', function(e) {
        const modal = document.getElementById('galleryModal');
        if (!modal || modal.style.display !== 'flex') return;
        
        if (e.key === 'Escape') {
            window.closeGalleryModal();
        } else if (e.key === 'ArrowLeft') {
            window.prevGalleryImage();
        } else if (e.key === 'ArrowRight') {
            window.nextGalleryImage();
        }
    });
});
