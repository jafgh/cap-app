import os
import re
import threading
import time
import base64
import io
import random
import requests
from PIL import Image as PILImage
import numpy as np
import cv2
import onnxruntime as ort
import torchvision.transforms as transforms

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.popup import Popup
from kivy.uix.image import Image
from kivy.uix.progressbar import ProgressBar
from kivy.uix.textinput import TextInput
from kivy.uix.anchorlayout import AnchorLayout
from kivy.uix.modalview import ModalView
from kivy.clock import Clock
from kivy.core.text import LabelBase
from kivy.core.window import Window
from kivy.graphics.texture import Texture

# --------------------------------------------------
# Register Arabic font
# --------------------------------------------------
LabelBase.register(name='Arabic', fn_regular='NotoNaskhArabic-Regular.ttf')

# --------------------------------------------------
# Constants
# --------------------------------------------------
CHARSET = '0123456789abcdefghijklmnopqrstuvwxyz'
CHAR2IDX = {c: i for i, c in enumerate(CHARSET)}
IDX2CHAR = {i: c for c, i in CHAR2IDX.items()}
NUM_CLASSES = len(CHARSET)
NUM_POS = 5
ONNX_MODEL_PATH = r"holako bag.onnx"

# --------------------------------------------------
# Preprocessing transform
# --------------------------------------------------
def preprocess_for_model():
    return transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.Grayscale(num_output_channels=3),
        transforms.ToTensor(),
        transforms.Normalize([0.5, 0.5, 0.5], [0.5, 0.5, 0.5]),
    ])

# --------------------------------------------------
# Main UI widget
# --------------------------------------------------
class MainWidget(BoxLayout):
    def __init__(self, **kwargs):
        super(MainWidget, self).__init__(orientation='vertical', spacing=10, padding=10, **kwargs)
        self.app = App.get_running_app()
        self.accounts = {}
        self.current_captcha = None

        # Notification Label
        self.notification = Label(text='', font_name='Arabic', font_size='16sp', size_hint=(1, None), height=30)
        self.add_widget(self.notification)

        # Add Account Button
        btn_layout = AnchorLayout(size_hint=(1, None), height=40)
        btn_add = Button(text='Add Account', size_hint=(None, None), size=(200, 40), on_release=self.on_add_account)
        btn_layout.add_widget(btn_add)
        self.add_widget(btn_layout)

        # Accounts ScrollView
        self.scroll = ScrollView(size_hint=(1, 1))
        self.accounts_box = BoxLayout(orientation='vertical', spacing=10, size_hint_y=None)
        self.accounts_box.bind(minimum_height=self.accounts_box.setter('height'))
        self.scroll.add_widget(self.accounts_box)
        self.add_widget(self.scroll)

        # Speed Label
        self.speed_label = Label(text='Preprocess: 0 ms | Predict: 0 ms', font_name='Arabic', font_size='14sp', size_hint=(1, None), height=30)
        self.add_widget(self.speed_label)

        # Load ONNX model
        if not os.path.exists(ONNX_MODEL_PATH):
            self.show_error(f"ONNX model not found at: {ONNX_MODEL_PATH}")
            return
        try:
            self.session = ort.InferenceSession(ONNX_MODEL_PATH, providers=['CPUExecutionProvider'])
        except Exception as e:
            self.show_error(f"Failed to load ONNX model: {e}")
            return

    def show_notification(self, msg, color=(1,1,1,1)):
        self.notification.color = color
        self.notification.text = msg
        print(msg)

    def show_error(self, msg):
        popup = Popup(title='Error', content=Label(text=msg, font_name='Arabic'), size_hint=(0.8, 0.4))
        popup.open()

    def generate_user_agent(self):
        ua_list = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:100.0) Gecko/20100101 Firefox/100.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 15_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
            "Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Mobile Safari/537.36",
            "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0"
        ]
        return random.choice(ua_list)

    def create_session(self):
        headers = {
            "User-Agent": self.generate_user_agent(),
            "Host": "api.ecsc.gov.sy:8443",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "ar,en-US;q=0.7,en;q=0.3",
            "Referer": "https://ecsc.gov.sy/login",
            "Content-Type": "application/json",
            "Source": "WEB",
            "Origin": "https://ecsc.gov.sy",
            "Connection": "keep-alive",
        }
        session = requests.Session()
        session.headers.update(headers)
        return session

    def on_add_account(self, instance):
        content = BoxLayout(orientation='vertical', spacing=10, padding=10)
        user_input = TextInput(hint_text='Username', multiline=False, font_name='Arabic')
        pwd_input = TextInput(hint_text='Password', multiline=False, password=True, font_name='Arabic')
        btn_login = Button(text='Login', size_hint=(1, None), height=40)
        content.add_widget(user_input)
        content.add_widget(pwd_input)
        content.add_widget(btn_login)
        popup = Popup(title='Add Account', content=content, size_hint=(0.8, 0.5))

        def do_login(btn):
            user = user_input.text.strip()
            pwd = pwd_input.text.strip()
            if not user or not pwd:
                return
            popup.dismiss()
            self.process_login(user, pwd)

        btn_login.bind(on_release=do_login)
        popup.open()

    def process_login(self, user, pwd):
        session = self.create_session()
        def login_thread():
            start = time.time()
            ok = self.login(user, pwd, session)
            elapsed = time.time() - start
            if ok:
                Clock.schedule_once(lambda dt: self.show_notification(f"Logged in {user} in {elapsed:.2f}s", (0,1,0,1)))
                self.accounts[user] = {'password': pwd, 'session': session}
                proc = self.fetch_process_ids(session)
                Clock.schedule_once(lambda dt: self.add_account_ui(user, proc))
            else:
                Clock.schedule_once(lambda dt: self.show_notification(f"Login failed for {user}", (1,0,0,1)))
        threading.Thread(target=login_thread, daemon=True).start()

    def login(self, username, password, session, retries=3):
        url = "https://api.ecsc.gov.sy:8443/secure/auth/login"
        payload = {"username": username, "password": password}
        for _ in range(retries):
            try:
                r = session.post(url, json=payload, verify=False)
                if r.status_code == 200:
                    return True
                else:
                    return False
            except:
                return False
        return False

    def fetch_process_ids(self, session):
        try:
            url = "https://api.ecsc.gov.sy:8443/dbm/db/execute"
            payload = {"ALIAS": "OPkUVkYsyq", "P_USERNAME": "WebSite", "P_PAGE_INDEX": 0, "P_PAGE_SIZE": 100}
            headers = {"Content-Type": "application/json", "Alias": "OPkUVkYsyq", "Referer": "https://ecsc.gov.sy/requests", "Origin": "https://ecsc.gov.sy"}
            r = session.post(url, json=payload, headers=headers, verify=False)
            if r.status_code == 200:
                return r.json().get("P_RESULT", [])
        except Exception as e:
            Clock.schedule_once(lambda dt: self.show_notification(f"Error fetching IDs: {e}", (1,0,0,1)))
        return []

    def add_account_ui(self, user, processes):
        acc_box = BoxLayout(orientation='vertical', size_hint_y=None, height=len(processes)*60+40, padding=5, spacing=5)
        acc_box.add_widget(Label(text=f"Account: {user}", font_name='Arabic', size_hint_y=None, height=30))
        for proc in processes:
            pid = proc.get("PROCESS_ID")
            name = proc.get("ZCENTER_NAME", "Unknown")
            row = BoxLayout(orientation='horizontal', size_hint_y=None, height=40)
            prog = ProgressBar(max=1, value=0)
            btn = Button(text=name, size_hint_x=None, width=200)
            btn.bind(on_release=lambda inst, u=user, p=pid, pb=prog: threading.Thread(target=self.handle_captcha, args=(u, p, pb), daemon=True).start())
            row.add_widget(btn)
            row.add_widget(prog)
            acc_box.add_widget(row)
        self.accounts_box.add_widget(acc_box)

    def handle_captcha(self, user, pid, prog):
        Clock.schedule_once(lambda dt: prog.setter('value')(prog, 0))
        data = self.get_captcha(self.accounts[user]['session'], pid, user)
        if data:
            self.current_captcha = (user, pid)
            Clock.schedule_once(lambda dt: self.show_captcha(data, prog))

    def get_captcha(self, session, pid, user):
        url = f"https://api.ecsc.gov.sy:8443/captcha/get/{pid}"
        try:
            while True:
                r = session.get(url, verify=False)
                if r.status_code == 200:
                    return r.json().get('file')
                elif r.status_code == 429:
                    time.sleep(0.1)
                elif r.status_code in (401,403):
                    if not self.login(user, self.accounts[user]['password'], session):
                        return None
                else:
                    Clock.schedule_once(lambda dt: self.show_notification(f"Server error: {r.status_code}", (1,0,0,1)))
                    return None
        except Exception as e:
            Clock.schedule_once(lambda dt: self.show_notification(f"Captcha error: {e}", (1,0,0,1)))
        return None

    def predict_captcha(self, pil_img):
        tf = preprocess_for_model()
        img = pil_img.convert("RGB")
        start_pre = time.time()
        x = tf(img).unsqueeze(0).numpy().astype(np.float32)
        end_pre = time.time()

        start_pred = time.time()
        ort_outs = self.session.run(None, {'input': x})[0]
        end_pred = time.time()

        ort_outs = ort_outs.reshape(1, NUM_POS, NUM_CLASSES)
        idxs = np.argmax(ort_outs, axis=2)[0]
        pred = ''.join(IDX2CHAR[i] for i in idxs)

        pre_ms = (end_pre - start_pre) * 1000
        pred_ms = (end_pred - start_pred) * 1000
        return pred, pre_ms, pred_ms

    def show_captcha(self, b64data, prog):
        # Decode and process image
        b64 = b64data.split(',')[1] if ',' in b64data else b64data
        raw = base64.b64decode(b64)
        pil = PILImage.open(io.BytesIO(raw))

        frames = []
        try:
            while True:
                frames.append(np.array(pil.convert("RGB")))
                pil.seek(pil.tell() + 1)
        except EOFError:
            pass
        stack = np.stack(frames).astype(np.uint8)
        bg = np.median(stack, axis=0).astype(np.uint8)
        gray = cv2.cvtColor(bg, cv2.COLOR_RGB2GRAY)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        enh = clahe.apply(gray)
        _, binary = cv2.threshold(enh, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
        proc_img = PILImage.fromarray(binary)

        pred, pre_ms, pred_ms = self.predict_captcha(proc_img)
        Clock.schedule_once(lambda dt: self.show_notification(f"Predicted CAPTCHA: {pred}", (0,0,1,1)))
        Clock.schedule_once(lambda dt: setattr(self.speed_label, 'text', f"Preprocess: {pre_ms:.2f} ms | Predict: {pred_ms:.2f} ms"))
        self.submit_captcha(pred)

        # Display image in popup
        texture = self.pil_to_texture(proc_img)
        img_widget = Image(texture=texture, size_hint=(1,1), allow_stretch=True)
        popup = Popup(title='CAPTCHA', content=img_widget, size_hint=(0.8,0.6))
        popup.open()
        # Update progress bar
        Clock.schedule_once(lambda dt: prog.setter('value')(prog, 1))

    def pil_to_texture(self, pil_img):
        arr = np.array(pil_img)
        h, w = arr.shape
        # grayscale to rgb
        buf = arr.tobytes()
        texture = Texture.create(size=(w, h), colorfmt='luminance')
        texture.blit_buffer(buf, colorfmt='luminance', bufferfmt='ubyte')
        return texture

    def submit_captcha(self, solution):
        user, pid = self.current_captcha
        session = self.accounts[user]['session']
        url = f"https://api.ecsc.gov.sy:8443/rs/reserve?id={pid}&captcha={solution}"
        try:
            r = session.get(url, verify=False)
            color = (0,1,0,1) if r.status_code == 200 else (1,0,0,1)
            Clock.schedule_once(lambda dt: self.show_notification(f"Submit response: {r.text}", color))
        except Exception as e:
            Clock.schedule_once(lambda dt: self.show_notification(f"Submit error: {e}", (1,0,0,1)))

class CaptchaApp(App):
    def build(self):
        Window.clearcolor = (1,1,1,1)
        return MainWidget()

if __name__ == '__main__':
    CaptchaApp().run()
