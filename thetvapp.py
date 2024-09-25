from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import re
import sys

# Setup main options
options = webdriver.ChromeOptions()
options.add_argument("--headless")  # To run Chrome in headless mode
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36"
options.add_argument(f"user-agent={user_agent}")
driver = webdriver.Chrome(options=options)

try:
    # First get all the live channels into a list
    homepage = "https://thetvapp.to/tv/"
    driver.get(homepage)
    channels = re.findall(r'a href="/tv/(.*?)/"', driver.page_source)  # Use raw string for regex

    # Save channel list to channellist.txt
    with open('channellist.txt', 'w') as channel_file:
        for i, channel in enumerate(channels):
            channel_name = channel.replace('-', ' ')
            print(i, channel_name)
            channel_file.write(f"{i}: {channel_name}\n")

    # Automatically default to selecting all channels
    print("No manual selection in GitHub Actions, defaulting to 'all' channels.")
    selections = range(len(channels))

    def extract_desired_url(requests):
        # Search for the desired URL in the requests
        for request in requests:
            if "m3u8?token=" in request:
                return request
        return None

    def get_get_requests():
        global driver
        try:
            # Execute JavaScript to capture network requests
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
            print("Captured Requests:", requests)  # Debugging line
            return requests
        except Exception as e:
            print("An error occurred while capturing requests:", e)
            return []

    # Access each selected channel page and trigger the play button
    with open('playlist.txt', 'w') as playlist_file:  # Open playlist.txt for writing
        for selection in selections:
            url = homepage + str(channels[selection])
            print(f'Scraping page for playlist at {url}')

            driver.get(url)

            # Click the play button to trigger network requests
            try:
                play_button = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.ID, "loadVideoBtn"))
                )
                play_button.click()

                # Wait a bit longer for the network requests to load
                time.sleep(6)  # Increased wait time for requests to be sent
            except Exception as e:
                print(f"Error clicking the play button: {e}")

            get_requests = get_get_requests()

            # Extract the desired URL
            if get_requests:
                desired_url = extract_desired_url(get_requests)
                if desired_url:
                    print("Playlist URL found:", desired_url)
                    playlist_file.write(f"{channels[selection]},{desired_url}\n")  # Write to playlist.txt
                else:
                    print("No Playlist URL found in the requests.")
            else:
                print("No GET requests found.")

finally:
    # Close the browser
    driver.quit()
    print("Browser closed. Exiting script.")
    sys.exit()  # Ensure the script exits here
