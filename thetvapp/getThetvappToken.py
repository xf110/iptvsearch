from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import re
import sys
from datetime import datetime
import time

# Setup main options
options = webdriver.ChromeOptions()
options.add_argument("--headless")  # To run Chrome in headless mode
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36"
options.add_argument(f"user-agent={user_agent}")
driver = webdriver.Chrome(options=options)

# Set implicit wait
driver.implicitly_wait(5)  # 设置隐式等待时间

try:
    # Directly access the channel page
    channel_url = "https://thetvapp.to/tv/ae-live-stream/"
    driver.get(channel_url)

    # Check if the page loaded correctly
    if "404" in driver.title or "Not Found" in driver.page_source:
        print("Error: Channel page not found.")
        sys.exit()

    # Wait for the play button to be clickable and click it
    try:
        play_button = WebDriverWait(driver, 15).until(
            EC.element_to_be_clickable((By.ID, "loadVideoBtn"))
        )
        play_button.click()
    except Exception as e:
        print("Error finding or clicking the play button:", e)
        sys.exit()

    # Wait a bit longer for the network requests to load
    time.sleep(5)  # Increased wait time for requests to be sent

    # Capture network requests to find the playlist URL
    requests = driver.execute_script("""
        var performance = window.performance || window.webkitPerformance || window.msPerformance || window.mozPerformance;
        if (!performance) {
            return [];
        }
        var entries = performance.getEntriesByType("resource");
        var urls = [];
        for (var i = 0; i < entries.length; i++) {
            urls.push(entries[i].name);
        }
        return urls;
    """)

    # Search for the desired URL and extract the token
    for request in requests:
        if "m3u8?token=" in request:
            # Extract the token value from the URL
            token_match = re.search(r'token=([^&]+)', request)
            if token_match:
                token = token_match.group(1)
                current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(f"{current_time} thetvapp Token value:", token)  # Output the token value with timestamp
                break
    else:
        print("No valid playlist URL found.")

finally:
    # Close the browser
    driver.quit()
    # print("Browser closed. Exiting script.")
    sys.exit()  # Ensure the script exits here
