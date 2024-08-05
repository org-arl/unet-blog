document.addEventListener("DOMContentLoaded", function(event) { 
/*
* Blog list toggle function
*/
const bloglistWrapper = document.querySelector('.bloglist-wrapper');
const bloglistClose = document.querySelector('.bloglist-close');
const bloglistShow = document.querySelector('.bloglist-show');

if(bloglistClose) { 
    bloglistClose.addEventListener('click', function() {
        if(bloglistWrapper.classList.contains('active')) {
            bloglistWrapper.classList.remove('active');
        }
    });
    bloglistShow.addEventListener('click', function() {
        bloglistWrapper.classList.add('active');
    })
}

});