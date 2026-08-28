document.addEventListener("DOMContentLoaded", function () {
  var button = document.getElementById("random-cert-fab");
  if (!button) {
    return;
  }

  var links = document.querySelectorAll(
    "table tbody tr td:first-child a"
  );
  if (!links.length) {
    button.style.display = "none";
    return;
  }

  button.addEventListener("click", function (event) {
    event.preventDefault();
    var target = links[Math.floor(Math.random() * links.length)];
    window.location.href = target.href;
  });
});
