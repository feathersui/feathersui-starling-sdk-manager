/*
Feathers SDK Manager
Copyright 2015 Bowler Hat LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package
{
	import feathers.controls.Button;
	import feathers.controls.ButtonGroup;
	import feathers.controls.Check;
	import feathers.controls.ImageLoader;
	import feathers.controls.Label;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.MetalWorksDesktopTheme;

	import flash.text.TextFormatAlign;

	import flash.text.engine.ElementFormat;

	import starling.text.TextFormat;

	import starling.textures.Texture;
	import starling.utils.Align;

	import utils.CustomStyleNames;

	public class FeathersSDKManagerTheme extends MetalWorksDesktopTheme
	{
		[Embed(source="/../assets/images/feathers-sdk-logo.png")]
		private static const FEATHERS_SDK_LOGO:Class;

		[Embed(source="/../assets/images/feathers-folder.png")]
		private static const FEATHERS_FOLDER_ICON:Class;

		[Embed(source="/../assets/images/adobe-air-logo.png")]
		private static const ADOBE_AIR_LOGO:Class;

		[Embed(source="/../assets/images/install-failed-icon.png")]
		private static const INSTALL_FAILED_ICON:Class;

		private static const ICON_SIZE:int = 160;

		public function FeathersSDKManagerTheme()
		{
			super();
		}

		protected var sdkLogoTexture:Texture;
		protected var adobeRuntimesLogoTexture:Texture;
		protected var directoryTexture:Texture;
		protected var installFailedIconTexture:Texture;

		override public function dispose():void
		{
			if(this.sdkLogoTexture)
			{
				this.sdkLogoTexture.dispose();
				this.sdkLogoTexture = null;
			}
			if(this.adobeRuntimesLogoTexture)
			{
				this.adobeRuntimesLogoTexture.dispose();
				this.adobeRuntimesLogoTexture = null;
			}
			if(this.directoryTexture)
			{
				this.directoryTexture.dispose();
				this.directoryTexture = null;
			}
			if(this.installFailedIconTexture)
			{
				this.installFailedIconTexture.dispose();
				this.installFailedIconTexture = null;
			}
			super.dispose();
		}

		override protected function initializeTextures():void
		{
			super.initializeTextures();
			this.sdkLogoTexture = Texture.fromEmbeddedAsset(FEATHERS_SDK_LOGO);
			this.adobeRuntimesLogoTexture = Texture.fromEmbeddedAsset(ADOBE_AIR_LOGO);
			this.directoryTexture = Texture.fromEmbeddedAsset(FEATHERS_FOLDER_ICON);
			this.installFailedIconTexture = Texture.fromEmbeddedAsset(INSTALL_FAILED_ICON);
		}

		override protected function initializeStyleProviders():void
		{
			super.initializeStyleProviders();

			this.getStyleProviderForClass(Button).setFunctionForStyleName(
				CustomStyleNames.ALTERNATE_STYLE_NAME_UPDATE_BUTTON, setUpdateButtonStyles);

			this.getStyleProviderForClass(Check).setFunctionForStyleName(
				CustomStyleNames.ALTERNATE_STYLE_NAME_ITEM_RENDERER_CHECK, setItemRendererCheckStyles);

			this.getStyleProviderForClass(ImageLoader).setFunctionForStyleName(
				CustomStyleNames.ALTERNATE_STYLE_NAME_FEATHERS_SDK_ICON_IMAGE_LOADER, setFeathersSDKIconImageLoaderStyles);
			this.getStyleProviderForClass(ImageLoader).setFunctionForStyleName(
				CustomStyleNames.ALTERNATE_STYLE_NAME_ADOBE_RUNTIMES_ICON_IMAGE_LOADER, setAdobeRuntimesIconImageLoaderStyles);
			this.getStyleProviderForClass(ImageLoader).setFunctionForStyleName(
				CustomStyleNames.ALTERNATE_STYLE_NAME_DIRECTORY_ICON_IMAGE_LOADER, setDirectoryIconImageLoaderStyles);
			this.getStyleProviderForClass(ImageLoader).setFunctionForStyleName(
				CustomStyleNames.ALTERNATE_STYLE_NAME_INSTALL_FAILED_ICON_IMAGE_LOADER, setInstallFailedIconImageLoaderStyles);

			this.getStyleProviderForClass(Label).setFunctionForStyleName(
				CustomStyleNames.ALTERNATE_STYLE_NAME_MESSAGE_LABEL, setMessageLabelStyles);
		}

		override protected function setAlertButtonGroupStyles(group:ButtonGroup):void
		{
			super.setAlertButtonGroupStyles(group);
			group.customLastButtonStyleName = Button.ALTERNATE_STYLE_NAME_CALL_TO_ACTION_BUTTON;
		}

		protected function setUpdateButtonStyles(button:Button):void
		{
			this.setCallToActionButtonStyles(button);
			button.layoutData = new AnchorLayoutData(this.gutterSize, this.gutterSize);
		}

		protected function setItemRendererCheckStyles(check:Check):void
		{
			this.setCheckStyles(check);

			//don't bold the fonts
			check.fontStyles = this.lightFontStyles;
			check.disabledFontStyles = this.lightDisabledFontStyles;

			//use a slightly larger gap because the item renderer has bigger
			//padding around the edges
			check.gap = this.gutterSize;
		}

		protected function setFeathersSDKIconImageLoaderStyles(loader:ImageLoader):void
		{
			loader.source = this.sdkLogoTexture;
			loader.setSize(ICON_SIZE, ICON_SIZE);
		}

		protected function setAdobeRuntimesIconImageLoaderStyles(loader:ImageLoader):void
		{
			loader.source = this.adobeRuntimesLogoTexture;
			loader.setSize(ICON_SIZE, ICON_SIZE);
		}

		protected function setDirectoryIconImageLoaderStyles(loader:ImageLoader):void
		{
			loader.source = this.directoryTexture;
			loader.setSize(ICON_SIZE, ICON_SIZE);
		}

		protected function setInstallFailedIconImageLoaderStyles(loader:ImageLoader):void
		{
			loader.source = this.installFailedIconTexture;
			loader.setSize(ICON_SIZE, ICON_SIZE);
		}

		protected function setMessageLabelStyles(label:Label):void
		{
			this.setLabelStyles(label);
			var styles:TextFormat = label.fontStyles.clone();
			styles.horizontalAlign = Align.CENTER;
			label.fontStyles = styles;
		}
	}
}