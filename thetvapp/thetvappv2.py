from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import re
import sys
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from concurrent.futures import ThreadPoolExecutor, as_completed  # Concurrency tools

# Setup main options
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36"
options.add_argument(f"user-agent={user_agent}")

# Threading: Each thread will have its own WebDriver instance
def setup_driver():
    return webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)

def extract_desired_url(requests):
    for request in requests:
        if "m3u8?token=" in request:
            return request
    return None

def get_get_requests(driver):
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
        return requests
    except Exception as e:
        print("Error capturing requests:", e)
        return []

def scrape_channel(channel, selection, homepage):
    driver = setup_driver()
    try:
        url = homepage + str(channel)
        print(f'Scraping page for playlist at {url}')
        driver.get(url)

        # Click the play button to trigger network requests
        try:
            play_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.ID, "loadVideoBtn"))
            )
            play_button.click()

            # Wait a bit longer for the network requests to load
            WebDriverWait(driver, 10).until(lambda d: len(get_get_requests(d)) > 0)
        except Exception as e:
            print(f"Error clicking the play button: {e}")

        get_requests = get_get_requests(driver)
        if get_requests:
            desired_url = extract_desired_url(get_requests)
            if desired_url:
                print(f"Playlist URL found: {desired_url}")
                return f"{channel},{desired_url}\n"
            else:
                print("No Playlist URL found in the requests.")
        else:
            print("No GET requests found.")
    finally:
        driver.quit()
        print(f"Browser closed for channel {selection}")
    return None

def main():
    homepage = "https://thetvapp.to/tv/"
    driver = setup_driver()
    driver.get(homepage)

    # Find all live channels
    channels = re.findall(r'a href="/tv/(.*?)/"', driver.page_source)
    driver.quit()

    print("Captured channels:", channels)
    selections = range(len(channels))

    # Use ThreadPoolExecutor to scrape channels concurrently
    with ThreadPoolExecutor(max_workers=5) as executor:  # Adjust max_workers based on your system resources
        futures = [executor.submit(scrape_channel, channels[selection], selection, homepage) for selection in selections]
        
        with open('thetvapplist.txt', 'w') as playlist_file:
            for future in as_completed(futures):
                result = future.result()
                if result:
                    playlist_file.write(result)
    
    print("Script finished. Exiting.")

if __name__ == "__main__":
    main()
    sys.exit(0)
