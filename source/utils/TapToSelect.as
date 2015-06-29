/*
Feathers SDK Installer
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
package utils
{
	import feathers.core.IToggle;

	import flash.geom.Point;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Stage;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class TapToSelect
	{
		private static const HELPER_POINT:Point = new Point();
		
		public function TapToSelect(target:IToggle = null)
		{
			this.target = target;
		}
		
		protected var _target:IToggle;
		
		public function get target():IToggle
		{
			return this._target;
		}
		
		public function set target(value:IToggle):void
		{
			if(this._target == value)
			{
				return;
			}
			if(this._target)
			{
				this._target.removeEventListener(TouchEvent.TOUCH, target_touchHandler);
			}
			this._target = value;
			if(this._target)
			{
				//if we're changing targets, and a touch is active, we want to
				//clear it.
				this._touchPointID = -1;
				this._target.addEventListener(TouchEvent.TOUCH, target_touchHandler);
			}
		}
		
		protected var _touchPointID:int = -1;
		
		protected var _isEnabled:Boolean = true;
		
		public function get isEnabled():Boolean
		{
			return this._isEnabled;
		}
		
		public function set isEnabled(value:Boolean):void
		{
			this._isEnabled = value
		}
		
		protected var _tapToDeselect:Boolean = false;
		
		public function get tapToDeselect():Boolean
		{
			return this._tapToDeselect;
		}
		
		public function set tapToDeselect(value:Boolean):void
		{
			this._tapToDeselect = value;
		}
		
		protected function target_touchHandler(event:TouchEvent):void
		{
			if(!this._isEnabled)
			{
				this._touchPointID = -1;
				return;
			}
			
			if(this._touchPointID >= 0)
			{
				//a touch has begun, so we'll ignore all other touches.
				var touch:Touch = event.getTouch(DisplayObject(this._target), null, this._touchPointID);
				if(!touch)
				{
					//this should not happen.
					return;
				}
				
				if(touch.phase == TouchPhase.ENDED)
				{
					var stage:Stage = this._target.stage;
					touch.getLocation(stage, HELPER_POINT);
					if(this._target is DisplayObjectContainer)
					{
						var isInBounds:Boolean = DisplayObjectContainer(this._target).contains(stage.hitTest(HELPER_POINT, true));
					}
					else
					{
						isInBounds = this._target === stage.hitTest(HELPER_POINT, true);
					}
					if(isInBounds)
					{
						if(this._tapToDeselect)
						{
							this._target.isSelected = !this._target.isSelected;
						}
						else
						{
							this._target.isSelected = true;
						}
					}
					
					//the touch has ended, so now we can start watching for a
					//new one.
					this._touchPointID = -1;
				}
				return;
			}
			else
			{
				//we aren't tracking another touch, so let's look for a new one.
				touch = event.getTouch(DisplayObject(this._target), TouchPhase.BEGAN);
				if(!touch)
				{
					//we only care about the began phase. ignore all other
					//phases when we don't have a saved touch ID.
					return;
				}
				
				//save the touch ID so that we can track this touch's phases.
				this._touchPointID = touch.id;
			}
		}
	}
}