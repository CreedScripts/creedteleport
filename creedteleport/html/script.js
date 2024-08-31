window.addEventListener('message', function(event) {
    if (event.data.type === 'countdown') {
        let count = event.data.count;
        const countdownElement = document.getElementById('countdown');
        const countElement = document.getElementById('count');

        countdownElement.classList.remove('hidden');
        countElement.innerText = count;

        const interval = setInterval(() => {
            count--;
            if (count >= 0) {
                countElement.innerText = count;
            } else {
                clearInterval(interval);
                countdownElement.classList.add('hidden');
            }
        }, 1000);
    }
});
