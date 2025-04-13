const inputBox = document.getElementById("search-box");
let searchDelay = null;
let chart = null; 


inputBox.addEventListener("input", () => {
  clearTimeout(searchDelay); 


  searchDelay = setTimeout(() => {
    const query = inputBox.value.trim();
    if (!query) return;


    fetch("/search_inputs", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ query }),
    })
      .then(res => res.json())
      .then(data => console.log("Search sent:", data))
      .catch(err => console.error("Something went wrong:", err));
  }, 300);
});

const loadTrending = () => {
  fetch("/api/analytics/trending")
    .then(res => res.json())
    .then(data => {
      const list = document.getElementById("trending-list");
      list.innerHTML = "";

      const top5 = data.slice(0, 5);

      if (top5.length === 0) {
        list.innerHTML = "<li>No recent searches</li>";
        return;
      }

      top5.forEach(item => {
        const li = document.createElement("li");
        li.textContent = `${item.query} (${item.count})`;
        list.appendChild(li);
      });

      updateChart(top5);
    })
    .catch(err => {
      console.error("Couldn't load trending data:", err);
    });
};

const updateChart = (data) => {
  const labels = data.map(item => item.query);
  const counts = data.map(item => item.count);

  const ctx = document.getElementById("trending-chart").getContext("2d");

  if (chart) {
    chart.data.labels = labels;
    chart.data.datasets[0].data = counts;
    chart.update();
  } else {
    chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            label: "Top 5 Trending Searches",
            data: counts,
            backgroundColor: "rgba(75, 192, 192, 0.6)",
            borderColor: "rgba(75, 192, 192, 1)",
            borderWidth: 1,
          },
        ],
      },
      options: {
        scales: {
          y: {
            beginAtZero: true,
            precision: 0,
          },
        },
      },
    });
  }
};

loadTrending();
setInterval(loadTrending, 10000);
