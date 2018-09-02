document.addEventListener("DOMContentLoaded", function(event) {
  particlesJS("main", {
    particles: {
      number: { value: 40, density: { enable: true, value_area: 500 } },
      color: { value: "#ffffff" },
      shape: {
        type: "circle"
      },
      opacity: {
        value: 0.5,
        random: true,
        anim: { enable: true, speed: 0.2, opacity_min: 0.1, sync: false }
      },
      size: {
        value: 3,
        random: true
      },
      line_linked: {
        enable: true,
        distance: 200,
        color: "#ffffff",
        opacity: 0.6,
        width: 1.5
      },
      move: {
        enable: true,
        speed: 0.5,
        direction: "none",
        random: true,
        straight: false,
        out_mode: "out"
      }
    },
    interactivity: {
      detect_on: "canvas",
      events: {
        onhover: { enable: true, mode: "grab" },
        onclick: { enable: true, mode: "bubble" },
        resize: true
      },
      modes: {
        grab: {
          distance: 160,
          line_linked: { opacity: 0.5 }
        },
        bubble: {
          distance: 120,
          size: 6,
          duration: 2,
          opacity: 0.7,
          speed: 3
        }
      }
    },
    retina_detect: true
  });
});
